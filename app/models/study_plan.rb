# Update exception class for the update_from_json method
class UpdateException < Exception
end


class StudyPlan < ActiveRecord::Base


  INITIAL_STUDY_PLAN_TIME_IN_YEARS = 3
  STUDY_PLAN_BUFFER_TIME_IN_YEARS = 1


  module RefCountExtension
    def add_or_increment_ref_count(*args)
      options = args.extract_options!
      scoped_course, = *args # Last comma forces nil value when args is empty

      scoped_course_id = options[:id] || scoped_course.id

      StudyPlan.transaction do
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = PlanCourse.where(:study_plan_id => plan_id,
                                                 :scoped_course_id => scoped_course_id).first

        if not existing_entry.nil?
          # Increment reference counter
          existing_entry.competence_ref_count += 1
          existing_entry.save!
        else
          scoped_course = ScopedCourse.find(scoped_course_id) if not scoped_course
          proxy_association.concat scoped_course
        end
      end
    end


    def remove_or_decrement_ref_count(*args)
      options = args.extract_options!
      scoped_course, = *args # Last comma forces nil value when args is empty

      scoped_course_id = options[:id] || scoped_course.id

      StudyPlan.transaction do
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = PlanCourse.where(:study_plan_id => plan_id,
                                                 :scoped_course_id => scoped_course_id).first

        if not existing_entry.nil?
          # Decrement reference counter
          existing_entry.competence_ref_count -= 1
          if existing_entry.competence_ref_count == 0 && (not existing_entry.manually_added)
            # The last competence to which this scoped_course is a depedency has been removed
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
  #  <- plan_courses
  #  <- study_plan_competences
  #  <- competences
  #  <- scoped_courses (plan_courses -> scoped_courses)
  #  <- study_plan_manual_courses
  #  <- manual_scoped_courses (study_plan_manual_courses -> scoped_courses)
  #  - created_at
  #  - updated_at


  # User & Curriculum
  belongs_to :user
  belongs_to :curriculum


  # Periods
  belongs_to :first_period, :class_name => 'Period'
  belongs_to :last_period, :class_name => 'Period'
  validates :first_period, presence: true
  validates :last_period, presence: true


  # Competences
  has_many  :study_plan_competences,
            :dependent => :destroy

  has_many :competences,
           :through => :study_plan_competences,
           :dependent => :destroy


  # Courses
  has_many  :plan_courses,
            :dependent => :destroy

  has_many  :abstract_courses,
            :through => :plan_courses,
            :source => :abstract_course,
            :dependent => :destroy

  has_many  :scoped_courses,
            :through => :plan_courses,
            :source => :scoped_course,
            :extend => RefCountExtension,
            :dependent => :destroy

  has_many  :study_plan_manual_courses,
            :class_name => 'PlanCourse',
            :dependent => :destroy,
            :conditions => { :manually_added => true }

  has_many  :manual_courses,
            :through => :study_plan_manual_courses,
            :source => :scoped_course,
            :dependent => :destroy,
            :uniq => true

  has_many  :course_instances,
            :through => :plan_courses,
            :source => :course_instance


  # Returns the period of the earliest scheduled plan course
  def period_of_earliest_plan_course
    earliest_plan_course = plan_courses.includes(:period).order('periods.begins_at ASC').first
    earliest_plan_course.nil? ? nil : earliest_plan_course.period
  end


  # Returns the period where the latest scheduled plan course ends
  # NB: This is not necessarily the last period extended to by a course in the
  # plan FIXME
  def ending_period_of_latest_plan_course
    latest_plan_course = plan_courses.includes(:period).order('periods.begins_at DESC').first
    latest_plan_course.nil? ? nil : latest_plan_course.ending_period
  end


  # Resets the first period.
  # By default, the "first period" is set as the current period unless
  #   - the plan already contains courses for preceding periods, or
  #   - the user has passed courses in preceding periods
  # in which case the period is set as the earliest of those
  def reset_first_period
    the_period_of_earliest_plan_course = period_of_earliest_plan_course
    the_period_of_earliest_user_course = user.period_of_earliest_user_course
    if not the_period_of_earliest_plan_course.nil? and not the_period_of_earliest_user_course.nil?
      period = the_period_of_earliest_plan_course.begins_at < the_period_of_earliest_user_course.begins_at ? the_period_of_earliest_plan_course : the_period_of_earliest_user_course
    elsif not the_period_of_earliest_plan_course.nil?
      period = the_period_of_earliest_plan_course
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
    the_ending_period_of_latest_plan_course = ending_period_of_latest_plan_course
    the_period_of_latest_user_course = user.period_of_latest_user_course
    if not the_ending_period_of_latest_plan_course.nil? and not the_period_of_latest_user_course.nil?
      period = the_ending_period_of_latest_plan_course.begins_at > the_period_of_latest_user_course.begins_at ? the_ending_period_of_latest_plan_course : the_period_of_latest_user_course
    elsif not the_ending_period_of_latest_plan_course.nil?
      period = the_ending_period_of_latest_plan_course
    elsif not the_period_of_latest_user_course.nil?
      period = the_period_of_latest_user_course
    end
    if period.nil?
      # If the user starts from a clean desk (no user nor plan courses) an
      # initial default is set
      reset_first_period if first_period.nil?
      period = Period.find_by_date(first_period.begins_at - 1 + 365*INITIAL_STUDY_PLAN_TIME_IN_YEARS)
      # FIXME: shouldn't be done here, but in the scheduler / user of this function
    else
      # We set the last as the one going on after a buffer time after the start
      # of the last starting course's last period
      the_period = Period.find_by_date(period.begins_at - 1 + 365*STUDY_PLAN_BUFFER_TIME_IN_YEARS)
      if the_period.nil?
        period = period.find_following(5*STUDY_PLAN_BUFFER_TIME_IN_YEARS).last
      end
    end
    self.last_period = period
    self.save
  end


  # Returns the periods included in the study plan
  def periods(options = {})
    #reset_first_period
    #reset_last_period

    #number_of_buffer_periods=0

#     Period.range(
#       self.first_period.find_preceding(number_of_buffer_periods).last,
#       self.last_period.find_following(number_of_buffer_periods).last
#     )
    Period.range(self.first_period, self.last_period)
  end


  # Adds scoped_courses to the plan according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"scoped_course_id": 71},
  #   {"scoped_course_id": 35},
  #   ...
  # ]
  def add_scoped_courses_from_json(json)
    scoped_courses_to_add = JSON.parse(json)

    feedback = {}

    scoped_courses_to_add.each do |scoped_course|
      status = self.add_scoped_course(scoped_course.id)
      if status == :ok
        feedback[scoped_course.id] = true
      else
        feedback[scoped_course.id] = false
      end
    end

    return feedback
  end


  # Removes plan_courses from the plan according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"plan_course_id": 71},
  #   {"plan_course_id": 35},
  #   ...
  # ]
  def remove_plan_courses_from_json(json)
    plan_courses_to_remove = JSON.parse(json)

    feedback = {}

    plan_courses_to_remove.each do |plan_course|
      status = self.remove_plan_course(plan_course.id)
      if status == :ok
        feedback[plan_course.id] = true
      else
        feedback[plan_course.id] = false
      end
    end

    return feedback
  end


  # Updates the plans plan courses according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"scoped_course_id": 71, "period_id": 1, "course_instance_id": 45},
  #   {"scoped_course_id": 35, "period_id": 2},
  #   {"scoped_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
  #   {"scoped_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
  #   ...
  # ]
  def update_plan_courses_from_json(json)

    plan_courses_to_update = JSON.parse(json)

    return 'empty' if plan_courses_to_update.length == 0

    # A scoped_course_id => accepted? dict which is returned by this function.
    feedback = {}

    # Index information by scoped_course_id and collect them
    new_course_data = {}
    scoped_course_ids = []
    plan_courses_to_update.each do |plan_course_to_update|
      scoped_course_id = plan_course_to_update['scoped_course_id']
      new_course_data[scoped_course_id] = plan_course_to_update
      scoped_course_ids.push(scoped_course_id)
    end

    puts "Received data by #{scoped_course_ids.length} ScopedCourse IDs: (#{scoped_course_ids})."
    y new_course_data

    # TODO: add new plan courses if not found

    self.plan_courses.where(scoped_course_id: scoped_course_ids).includes(:scoped_course).each do |plan_course|

      # Fetch the related abstract and scoped_course information
      scoped_course = plan_course.scoped_course
      scoped_course_id = plan_course.scoped_course_id
      abstract_course_id = plan_course.scoped_course.abstract_course_id

      # Initially, mark the update as rejected.
      feedback[scoped_course_id] = false

      # Load the data for this plan_course
      new_course = new_course_data[scoped_course_id]

      new_period_id = new_course['period_id']
      new_length = new_course['length']
      new_credits = new_course['credits']
      new_grade = new_course['grade']
      new_course_instance_id = nil
      new_custom = false

      begin
        # Raise an error if lacking basic necessities
        raise UpdateException.new, "No period_id defined!" if new_period_id.nil?
        raise UpdateException.new, "No length defined!" if new_length.nil?
        raise UpdateException.new, "No credits defined!" if new_credits.nil?

        # Fetch the available course instance if available
        course_instance = CourseInstance.where(abstract_course_id: abstract_course_id, period_id: new_period_id).first

        # Determine whether the course should be regarded as 'instance bound'
        if course_instance.nil? or course_instance.length != new_length
          new_course_instance_id = nil
        else
          new_course_instance_id = course_instance.id
        end

        # Determine whether the course should be regarded as customized
        new_custom = scoped_course.credits != new_credits

        # Save possible changes to the plan_course
        changed =
            plan_course.period_id != new_period_id ||
            plan_course.course_instance_id != new_course_instance_id ||
            plan_course.length != new_length ||
            plan_course.credits != new_credits ||
            plan_course.grade != new_grade ||
            plan_course.custom != new_custom

        if changed
          plan_course.period_id = new_period_id
          plan_course.course_instance_id = new_course_instance_id
          plan_course.length = new_length
          plan_course.credits = new_credits
          plan_course.grade = new_grade
          plan_course.custom = new_custom
          plan_course.save
        end

        # No we're done! =) Mark the course as accepted.
        feedback[scoped_course_id] = true

      # On error, the plan_course is rejected.
      rescue UpdateException => message
        puts "ERROR '#{message}' when updating the plan course: #{new_course}!"
      end
    end

    # Return the dict of accepted plan_courses_to_update.
    return feedback
  end


  # Updates the plan according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"scoped_course_id": 71, "period_id": 1, "course_instance_id": 45},
  #   {"scoped_course_id": 35, "period_id": 2},
  #   {"scoped_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
  #   {"scoped_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
  #   ...
  # ]
  def update_from_json(json)

    feedback = {}

    if json.has_key?('scoped_courses_to_add')
      feedback['scoped_courses_to_add'] = self.add_courses_from_json( json['scoped_courses_to_add'] )
    end

    if json.has_key?('plan_courses_to_remove')
      feedback['plan_courses_to_remove'] = self.remove_courses_from_json( json['plan_courses_to_remove'] )
    end

    if json.has_key?('plan_courses_to_update')
      feedback['plan_courses_to_update'] = self.update_courses_from_json( json['plan_courses_to_update'] )
    end

    if feedback.empty?
      feedback['status'] = 'error'
    else
      feedback['status'] = 'ok'
    end

    return feedback
  end


  def add_competence(competence)
    # Dont't do anything if the study plan already has this competence
    return if has_competence?(competence)

    competences << competence

    # FIXME: This breaks if prerequisites include Competences

    # Calculate union of existing and new scoped_courses, without duplicates
    scoped_courses_array = self.scoped_courses | competence.courses_recursive

    self.scoped_courses = scoped_courses_array

    # FIXME !!!
    self.plan_courses.includes(:scoped_course).find_each do |plan_course|
      plan_course.abstract_course = plan_course.scoped_course.abstract_course
      plan_course.save
    end
  end


  # Removes the given competence and courses that are needed by it. Courses that are still needed by the remaining competences, are not removed. Also, manually added courses are not reomved.
  def remove_competence(competence)
    # Remove competence
    competences.delete(competence)

    self.scoped_courses = needed_scoped_courses(self.competences).to_a
  end


  def has_competence?(competence)
    competences.include? competence
  end


  # Adds the scoped course into the study plan
  def add_scoped_course(scoped_course_id)
    scoped_course = ScopedCourse.find(scoped_course_id)

    return :not_found if not scoped_course

    # Dont't do anything if user has already selected this scoped_course
    return :already_added if @user.study_plan.scoped_courses.exists?(scoped_course)

    # Add scoped_course to study plan
    PlanCourse.create(
      :study_plan_id       =>  @user.study_plan.id,
      :abstract_course_id  =>  scoped_course.abstract_course_id,
      :scoped_course_id    =>  scoped_course.id,
      :credits             =>  scoped_course.credits,
      :grade               =>  nil,
      :manually_added      =>  true
      #:course_instance     =>  nil,                   # deprecated
      #:period              =>  nil                    # not specified here
    )

    return :ok
  end


  # Removes the plan course from the study plan
  def remove_plan_course(plan_course_id)
    plan_course = self.plan_courses.find(plan_course_id)

    return :not_found if not plan_course

    plan_course.destroy

    return :ok
  end


  # Returns a list of scoped_courses than can be deleted if the given competence is dropped from the study plan
  def deletable_scoped_courses(competence)
    # Make an array of competences that the user has after deleting the given competence
    remaining_competences = competences.clone
    remaining_competences.delete(competence)
    puts "#{competences.size} / #{remaining_competences.size}"

    # Make a list of scoped_courses that are needed by the remaining competences
    needed_scoped_courses = needed_scoped_courses(remaining_competences)

    scoped_courses.to_set - needed_scoped_courses
  end


  # Returns a set of scoped_courses that are needed by the given competences
  # competences: a collection of competence objects
  def needed_scoped_courses(competences)
    # Make a list of scoped_courses that are needed by remaining profiles
    needed_scoped_courses = Set.new
    competences.each do |competence|
      needed_scoped_courses.merge(competence.courses_recursive)
    end

    # Add manually added scoped_courses to the list
    needed_scoped_courses.merge(manual_scoped_courses)
  end

end
