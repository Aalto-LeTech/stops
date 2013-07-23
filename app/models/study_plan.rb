# Update exception class for the update_from_json method
class UpdateException < Exception
end


class StudyPlan < ActiveRecord::Base


  DEFAULT_STUDY_PLAN_TIME_IN_YEARS = 5


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


  #  create_table "study_plans", :force => true do |t|
  #    t.datetime "created_at",      :null => false
  #    t.datetime "updated_at",      :null => false
  #    t.integer  "user_id"
  #    t.integer  "curriculum_id",   :null => false
  #    t.integer  "first_period_id"
  #    t.integer  "last_period_id"
  #  end

  # members
  #  -> user
  #  -> curriculum
  #  -> first_period
  #  -> last_period
  #  <- study_plan_courses
  #  <- study_plan_competences
  #  <- competences (study_plan_courses -> scoped_courses)
  #  <- courses (study_plan_courses -> scoped_courses)
  #  <- study_plan_manual_courses
  #  <- manual_courses (study_plan_manual_courses -> scoped_courses)
  #  - created_at
  #  - updated_at


  # User & Curriculum
  belongs_to :user
  belongs_to :curriculum


  # Periods
  belongs_to :first_period, :class_name => 'Period'
  belongs_to :last_period, :class_name => 'Period'


  #has_one :first_period, :class_name => 'Period',
  #        :primary_key => :first_period_id,
  #        :foreign_key => :id

  #has_one :last_period, :class_name => 'Period',
  #        :primary_key => :last_period_id,
  #        :foreign_key => :id


  # Competences
  has_many  :study_plan_competences,
            :dependent => :destroy

  has_many :competences,
           :through => :study_plan_competences,
           :dependent => :destroy


  # Courses
  has_many  :study_plan_courses,
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


  # Returns the period of the earliest scheduled study plan course
  def period_of_earliest_study_plan_course
    study_plan_courses.includes(:period).order('periods.begins_at ASC').first.period
  end


  # Returns the period of the latest scheduled study plan course
  def period_of_latest_study_plan_course
    study_plan_courses.includes(:period).order('periods.begins_at DESC').first.period
  end


  # Resets the first period.
  # By default, the "first period" is set as the current period unless
  #   - the plan already contains courses for preceding periods, or
  #   - the user has passed courses in preceding periods
  # in which case the period is set as the earliest of those
  def reset_first_period
    the_period_of_earliest_study_plan_course = period_of_earliest_study_plan_course
    the_period_of_earliest_user_course = user.period_of_earliest_user_course
    if not the_period_of_earliest_study_plan_course.nil? and not the_period_of_earliest_user_course.nil?
      period = the_period_of_earliest_study_plan_course.begins_at < the_period_of_earliest_user_course.begins_at ? the_period_of_earliest_study_plan_course : the_period_of_earliest_user_course
    elsif not the_period_of_earliest_study_plan_course.nil?
      period = the_period_of_earliest_study_plan_course
    elsif not the_period_of_earliest_user_course.nil?
      period = the_period_of_earliest_user_course
    else
      period = Period.current
    end
    self.first_period = period
    self.save
  end


  # Resets the last period.
  # The algorithm works pretty much opposite to its counterpart, the
  # reset_first_period.
  def reset_last_period
    period = nil
    the_period_of_latest_study_plan_course = period_of_latest_study_plan_course
    the_period_of_latest_user_course = user.period_of_latest_user_course
    if not the_period_of_latest_study_plan_course.nil? and not the_period_of_latest_user_course.nil?
      period = the_period_of_latest_study_plan_course.begins_at > the_period_of_latest_user_course.begins_at ? the_period_of_latest_study_plan_course : the_period_of_latest_user_course
    elsif not the_period_of_latest_study_plan_course.nil?
      period = the_period_of_latest_study_plan_course
    elsif not the_period_of_latest_user_course.nil?
      period = the_period_of_latest_user_course
    end
    if period.nil? or period.ends_at - first_period.begins_at < 365*DEFAULT_STUDY_PLAN_TIME_IN_YEARS
      # In any case, the time difference between the first and the last is set
      # as at least five years, by default
      period = Period.find_by_date(first_period.begins_at - 1 + 365*DEFAULT_STUDY_PLAN_TIME_IN_YEARS)
    end
    self.last_period = period
    self.save
  end


  # Returns the periods included into the study plan
  def periods
    reset_first_period if first_period.nil?
    reset_last_period if last_period.nil?
    Period.range(first_period, last_period)
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

    self.study_plan_courses.where(scoped_course_id: scoped_course_ids).includes(:scoped_course).each do |study_plan_course|

      # Fetch the related abstract and scoped_course information
      scoped_course = study_plan_course.scoped_course
      scoped_course_id = study_plan_course.scoped_course_id
      abstract_course_id = study_plan_course.scoped_course.abstract_course_id

      # Initially, mark the update as rejected.
      accepted[scoped_course_id] = false

      # Load the data for this study_plan_course
      new_course = new_courses[scoped_course_id]

      new_period_id = new_course['period_id']
      new_credits = new_course['credits']
      new_length = new_course['length']
      new_grade = new_course['grade']
      new_course_instance_id = nil
      new_custom = false

      begin
        # Raise an error if lacking basic necessities
        raise UpdateException.new, "No period_id defined!" if new_period_id.nil?
        raise UpdateException.new, "No credits defined!" if new_credits.nil?
        raise UpdateException.new, "No length defined!" if new_length.nil?

        # Fetch the available course instance if available
        course_instance = CourseInstance.where(abstract_course_id: abstract_course_id, period_id: new_period_id).first

        # Determine whether the course should be regarded as customized
        if course_instance.nil?
          new_custom = true
        else
          new_custom =
            course_instance.length != new_length ||
            scoped_course.credits != new_credits
          new_course_instance_id = course_instance.id
        end

        # Save possible changes to the study_plan_course
        changed =
            study_plan_course.period_id != new_period_id ||
            study_plan_course.course_instance_id != new_course_instance_id ||
            study_plan_course.credits != new_credits ||
            study_plan_course.length != new_length ||
            study_plan_course.custom != new_custom

        if changed
          study_plan_course.period_id = new_period_id
          study_plan_course.course_instance_id = new_course_instance_id
          study_plan_course.credits = new_credits
          study_plan_course.length = new_length
          study_plan_course.custom = new_custom
          study_plan_course.save
        end

        # If a grade was defined
        if not new_grade.nil?
          if not new_course_instance_id.nil?
            existing_user_course = self.user.user_courses.where(course_instance_id: new_course_instance_id).first
          else
            existing_user_course = self.user.user_courses.where(abstract_course_id: abstract_course_id).first
          end
          if new_grade > 0
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
          elsif existing_user_course and new_grade == -1
            # The user course is flagged for destruction
            existing_user_course.destroy
          end
        end

        # No we're done! =) Mark the course as accepted.
        accepted[scoped_course_id] = true

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


  # Returns an ordered array of periods with scheduled courses (see code)
  def ordered_array_of_periods_with_scheduled_courses
    hash = {}
    study_plan_courses.where( 'period_id IS NOT NULL' ).order( 'period_id' ).each do |study_plan_course|
      # find the periods over which this course spans
      period = study_plan_course.period  # start period
      length = study_plan_course.length
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
