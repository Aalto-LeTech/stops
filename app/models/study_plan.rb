class StudyPlan < ActiveRecord::Base

  module RefCountExtension
    def add_or_increment_ref_count(*args)
      options = args.extract_options!
      course, = *args # Last comma forces nil value when args is empty

      course_id = options[:id] || course.id

      StudyPlan.transaction do
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = StudyPlanCourse.where(:study_plan_id => plan_id,
                                                 :scoped_course_id => course_id).first

        if not existing_entry.nil?
          # Increment reference counter
          existing_entry.competence_ref_count += 1
          existing_entry.save!
        else
          course = ScopedCourse.find(course_id) if not course
          proxy_association.concat course
        end
      end
    end


    def remove_or_decrement_ref_count(*args)
      options = args.extract_options!
      course, = *args # Last comma forces nil value when args is empty

      course_id = options[:id] || course.id

      StudyPlan.transaction do
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = StudyPlanCourse.where(:study_plan_id => plan_id,
                                                 :scoped_course_id => course_id).first

        if not existing_entry.nil?
          # Decrement reference counter
          existing_entry.competence_ref_count -= 1
          if existing_entry.competence_ref_count == 0 && (not existing_entry.manually_added)
            # The last competence to which this course is a depedency has been removed
            existing_entry.destroy
            raise "Course could not be deleted" unless existing_entry.destroyed?
          else
            # Save the decremented counter
            existing_entry.save!
          end
        end
      end
    end
  end

  belongs_to :user

  belongs_to :curriculum

  has_many  :study_plan_courses,
            :dependent => :destroy

  has_many  :study_plan_competences,
            :dependent => :destroy

  has_many  :courses,
            :through => :study_plan_courses,
            :source => :scoped_course,
            :extend => RefCountExtension,
            :dependent => :destroy

  has_many  :study_plan_manual_courses,
            :class_name => 'StudyPlanCourse',
            :dependent => :destroy,
            :conditions => { :manually_added => true }

  has_many  :manual_courses,
            :through => :study_plan_manual_courses,
            :source => :scoped_course,
            :dependent => :destroy,
            :uniq => true

  has_many :competences,
           :through => :study_plan_competences,
           :dependent => :destroy


  def as_json(options={})
    super(options.merge({
      :only => [:curriculum_id],
      :include => {
        :study_plan_courses => {
          :only => [:scoped_course_id, :period_id]
        }
      },
    }))
  end

  # Updates the database according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"scoped_course_id": 71, "period_id": 1, "course_instance_id": 45},
  #   {"scoped_course_id": 35, "period_id": 2},
  #   {"scoped_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
  #   {"scoped_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
  #   ...
  # ]
  class UpdateException < Exception
  end

  def update_from_json(json)
    plan_courses = JSON.parse(json)

    return if plan_courses.length == 0

    # A scoped_course_id => accepted? dict which is returned by this function.
    accepted = {}

    # Index information by scoped_course_id and collect them
    new_courses = {}
    scoped_course_ids = []
    plan_courses.each do |plan_course|
      scoped_course_id = plan_course['scoped_course_id']
      new_courses[scoped_course_id] = plan_course
      scoped_course_ids.push(scoped_course_id)
    end

    puts "Received data by #{scoped_course_ids.length} ScopedCourse IDs: (#{scoped_course_ids})."
    y new_courses

    self.study_plan_courses.where(scoped_course_id: scoped_course_ids).each do |study_plan_course|

      # Initially, mark the update as rejected.
      accepted[study_plan_course.scoped_course_id] = false

      # Fetch the abstract_course_id
      abstract_course_id = study_plan_course.scoped_course.abstract_course_id

      # Load the data for this study_plan_course
      new_course = new_courses[study_plan_course.scoped_course_id]

      new_period_id = new_course['period_id']
      new_course_instance_id = new_course['course_instance_id']
      new_credits = new_course['credits']
      new_length = new_course['length']
      new_grade = new_course['grade']

      begin
        # Raise an error if lacking basic necessities
        raise UpdateException.new, "No credits defined!" if not defined?(new_credits)

        # If a period_id was defined..
        if defined?(new_period_id)
          # .. but it's not valid..
          if not Period.exists?(new_period_id)
            # .. raise an error!
            raise UpdateException.new, "Invalid period_id!"
          end
        end

        # If a course_instance_id was defined
        if defined?(new_course_instance_id)
          # Is it valid?
          course_instance = CourseInstance.find_by_id(new_course_instance_id)
          if course_instance
            # And does the requested course instance exist as such?
            changed =
              course_instance.abstract_course_id != abstract_course_id ||
              course_instance.period_id != new_period_id ||
              course_instance.length != new_length

            if changed
              raise UpdateException.new, "Planned course_instance differs from the one in the database!"
            end
          else
            if new_course_instance_id == nil
              s = 'nil'
            else
              s = new_course_instance_id.to_s
            end
            raise UpdateException.new, "Invalid course_instance_id #{s}!"
          end
        else
          # With no course_instance_id given the user apparently insists that even
          # though the database doesn't agree such an instance exists...
          # We have two choices: either we create a new instance with the given specs
          # or we leave it nil -- also to the possibly created user_course
          raise UpdateException.new, "Procedure not implemented yet!"
        end

        # Save possible changes to the study_plan_course
        changed =
            study_plan_course.period_id != new_period_id ||
            study_plan_course.course_instance_id != new_course_instance_id ||
            study_plan_course.credits != new_credits

        if changed
          study_plan_course.period_id = new_period_id
          study_plan_course.course_instance_id = new_course_instance_id
          study_plan_course.credits = new_credits
          study_plan_course.save
        end

        # If a grade was defined
        if defined?(new_grade)
          existing_user_course = self.user.user_courses.where(course_instance_id: new_course_instance_id).first
          # And an existing user_course exists
          if existing_user_course
            # Save the possible changes to the user_course
            changed =
                existing_user_course.grade != new_grade ||
                existing_user_course.credits != new_credits

            if changed
              existing_user_course.grade = new_grade
              existing_user_course.credits = new_credits
              existing_user_course.save
            end
          else
            # If there is no existing user_course, create one
            UserCourse.create(
              user_id:             self.user_id,
              abstract_course_id:  abstract_course_id,
              course_instance_id:  new_course_instance_id,
              grade:               new_grade,
              credits:             new_credits
            )
          end
        end

        # No we're done! =) Mark the course as accepted.
        accepted[study_plan_course.scoped_course_id] = true

      # On error, the plan_course is rejected.
      rescue UpdateException => message
        puts "ERROR '#{message}' when updating database from the plan_course: #{new_course}!"
      end
    end

    # Return the dict of accepted plan_courses.
    return accepted
  end

  def add_competence(competence)
    # Dont't do anything if the study plan already has this competence
    return if has_competence?(competence)

    competences << competence

    # FIXME: This breaks if prerequisites include Competences

    # Calculate union of existing and new courses, without duplicates
    courses_array = self.courses | competence.courses_recursive

    self.courses = courses_array
  end

  # Removes the given competence and courses that are needed by it. Courses that are still needed by the remaining competences, are not removed. Also, manually added courses are not reomved.
  def remove_competence(competence)
    # Remove competence
    competences.delete(competence)

    self.courses = needed_courses(self.competences).to_a
  end

  def has_competence?(competence)
    competences.include? competence
  end

  # Returns a list of courses than can be deleted if the given competence is dropped from the study plan
  def deletable_courses(competence)
    # Make an array of competences that the user has after deleting the given competence
    remaining_competences = competences.clone
    remaining_competences.delete(competence)
    puts "#{competences.size} / #{remaining_competences.size}"

    # Make a list of courses that are needed by the remaining competences
    needed_courses = needed_courses(remaining_competences)

    courses.to_set - needed_courses
  end

  # Returns a set of courses that are needed by the given competences
  # competences: a collection of competence objects
  def needed_courses(competences)
    # Make a list of courses that are needed by remaining profiles
    needed_courses = Set.new
    competences.each do |competence|
      needed_courses.merge(competence.courses_recursive)
    end

    # Add manually added courses to the list
    needed_courses.merge(manual_courses)
  end

  # Returns whether the given course is included in the study plan or not
  def includes?( abstract_course )
    study_plan_courses.where( 'scoped_course.abstract_course = ?', abstract_course ).count > 0
  end

  # Returns the study plan courses that are scheduled
  def scheduled_courses
    study_plan_courses.where( 'period_id IS NOT NULL' ).order( 'period_id' )
  end

  # Returns the study plan courses that are unscheduled
  def unscheduled_courses
    study_plan_courses.where( 'period_id IS NULL' ).sort { |a, b| a.course_code <=> b.course_code }
  end

  # Returns the periods that contain scheduled courses
  def scheduled_periods
    Period.where( id: ( scheduled_courses.map { |course| course.period_id } ).uniq ).order( begins_at )
  end

  # Returns the courses scheduled to start in the given period
  def courses_scheduled_to_period( period )
    study_plan_courses.where( period_id: period.id ).sort { |a, b| a.course_code <=> b.course_code }
  end

  # Returns an ordered array of periods with scheduled courses (see code)
  def ordered_array_of_periods_with_scheduled_courses
    hash = {}
    scheduled_courses.each do |study_plan_course|
      # find the periods over which this course spans
      period = study_plan_course.period  # start period
      length = study_plan_course.length_or_one
      periods = length > 1 ? period.find_next_periods( length - 1 ) << period : [ period ]
      # add this course as 'ongoing' to these periods
      periods.each_with_index do |period, i|
        if hash.has_key?( period ) == false
          hash[ period ] = {
            starting_courses:    [],
            continuing_courses:  [],
            ending_courses:      [],
            total_courses:       0,
            total_load:          0
          }
        end
        # cumulate data
        hash_syms = []
        hash_syms << ( i == periods.size - 1 ? :starting_courses : :continuing_courses )
        hash_syms << :ending_courses if periods.size == 1 or i == periods.size - 2
        #hash_sym = (i == 0 ? :starting_courses : (i == periods.size - 1 ? :ending_courses : :continuing_courses ) )
        hash_syms.each do |hash_sym|
          hash[ period ][ hash_sym ] << study_plan_course
        end
        hash[ period ][ :total_load ] += study_plan_course.credits / length
        hash[ period ][ :total_courses ] += 1
      end
    end
    # transform the hash into an ordered array (by period start date)
    array = []
    hash.keys.each do |period|
      array << {
        period:  period,
        data:    hash[ period ]
      }
    end
    array.sort { |a, b| a[:period].begins_at <=> b[:period].begins_at }
  end

end
