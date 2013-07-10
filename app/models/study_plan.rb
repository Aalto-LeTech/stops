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

  # updates the database according to the data received TODO: create user_courses
  def update_from_json(json)
    new_plan = JSON.parse(json)

    # Index information by scoped_course_id
    new_courses = {}   # scoped_course_id => {scoped_course_id: 1, period_id: 2, course_instance_id: 3, grade: 4, credits: 5}
    new_plan.each do |plan_course|
      scoped_course_id = plan_course['scoped_course_id']
      new_courses[scoped_course_id] = plan_course
    end

    self.study_plan_courses.each do |studyplan_course|
      new_course = new_courses[studyplan_course.scoped_course_id]

      new_period_id = new_course['period_id']
      new_course_instance_id = new_course['course_instance_id']
      new_grade = new_course['grade']
      new_credits = new_course['credits']

      changed =
          studyplan_course.period_id != new_period_id ||
          studyplan_course.course_instance_id != new_course_instance_id ||
          studyplan_course.grade != new_grade ||
          studyplan_course.credits != new_credits

      if changed
        studyplan_course.period_id = new_period_id
        studyplan_course.course_instance_id = new_course_instance_id
        studyplan_course.grade = new_grade
        studyplan_course.credits = new_credits
        studyplan_course.save
      end
    end
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
