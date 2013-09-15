# Update exception class for the update_from_json method
class UpdateException < Exception
end


class StudyPlan < ActiveRecord::Base


  INITIAL_STUDY_PLAN_TIME_IN_YEARS = 7


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
  #  <- plan_competences
  #  <- competences
  #  <- plan_courses
  #  <- abstract_courses (plan_courses -> abstract_courses)
  #  <- scoped_courses (plan_courses -> scoped_courses)
  #  <- extra_plan_courses
  #  <- extra_scoped_courses (extra_plan_courses -> scoped_courses)
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
  has_many  :plan_competences,
            :dependent => :destroy

  has_many :competences,
           :through => :plan_competences

  # Courses
  has_many  :plan_courses,
            :dependent => :destroy

  has_many  :passed_courses,
            :class_name => 'PlanCourse',
            :conditions  => proc { 'grade > 0' }

  has_many  :abstract_courses,
            :through => :plan_courses,
            :source => :abstract_course,

  has_many  :scoped_courses,
            :through => :plan_courses,
            :source => :scoped_course,
            :extend => RefCountExtension

  has_many  :extra_plan_courses,
            :class_name => 'PlanCourse',
            :conditions => { :manually_added => true }

  has_many  :extra_scoped_courses,
            :through => :extra_plan_courses,
            :source => :scoped_course,
            :uniq => true

  has_many  :course_instances,
            :through => :plan_courses,
            :source => :course_instance

  # Skills
  has_many  :skills,
            :through     => :scoped_courses,
            :source      => :skills


  # Returns the periods included in the study plan
  def periods(options = {})
    #reset_first_period
    #reset_last_period

    #number_of_buffer_periods=4

    #Period.range(
    # self.first_period.find_preceding(number_of_buffer_periods).last,
    # self.last_period.find_following(number_of_buffer_periods).last
    #)
    Period.range(self.first_period, self.last_period)
  end


  # Get passed courses
  def passed?(abstract_course)
    self.plan_courses.exists?(['abstract_course_id = ? AND grade > 0', abstract_course.id])
  end


  # Adds scoped_courses to the plan according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"scoped_course_id": 71},
  #   {"scoped_course_id": 35},
  #   ...
  # ]
  def add_scoped_courses_from_json(json)
    scoped_course_ids_to_add = JSON.parse(json)

    puts "ids to add: %s" % [ scoped_course_ids_to_add ]

    feedback = {}

    scoped_course_ids_to_add.each do |scoped_course_id|
      fdbck = self.add_scoped_course(scoped_course_id.to_i, is_manually_added=true)
      if fdbck.is_a? PlanCourse
        feedback[scoped_course_id] = fdbck.as_json(root: false)
      else
        feedback[scoped_course_id] = false
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
    plan_course_ids_to_remove = JSON.parse(json)

    puts "ids to remove: %s" % [ plan_course_ids_to_remove ]

    feedback = {}

    plan_course_ids_to_remove.each do |plan_course_id|
      status = self.remove_plan_course(plan_course_id.to_i)
      if status == :ok
        feedback[plan_course_id] = true
      else
        feedback[plan_course_id] = false
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

    if json.has_key?('scoped_course_ids_to_add')
      feedback['scoped_course_ids_to_add'] = self.add_scoped_courses_from_json( json['scoped_course_ids_to_add'] )
    end

    if json.has_key?('plan_course_ids_to_remove')
      feedback['plan_course_ids_to_remove'] = self.remove_plan_courses_from_json( json['plan_course_ids_to_remove'] )
    end

    if json.has_key?('plan_courses_to_update')
      feedback['plan_courses_to_update'] = self.update_plan_courses_from_json( json['plan_courses_to_update'] )
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

    # Calculate the scoped_courses to add
    required_courses = competence.recursive_prereqs.where(:type => 'ScopedCourse').all
    scoped_course_ids_to_add = required_courses - self.scoped_courses

    scoped_course_ids_to_add.each do |scoped_course|
      self.add_course(scoped_course)
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
  def add_course(scoped_course, is_manually_added=false)
    if scoped_course.is_a? Integer
      scoped_course = ScopedCourse.find(scoped_course)
    end

    # Dont't do anything if the plan already contains this scoped_course
    # FIXME: DB doesn't accept duplicate scoped_courses for a plan atm.
    return :already_added if self.scoped_courses.exists?(scoped_course)

    # Add scoped_course to study plan
    plan_course = PlanCourse.create(
      :study_plan_id       =>  self.id,
      :abstract_course_id  =>  scoped_course.abstract_course_id,
      :scoped_course_id    =>  scoped_course.id,
      :course_instance_id  =>  nil,
      :period_id           =>  nil,
      :length              =>  nil,
      :credits             =>  scoped_course.credits,
      :grade               =>  0,
      :custom              =>  false,
      :manually_added      =>  is_manually_added,
    )
 
    return plan_course
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

    # Make a list of scoped_courses that aren't needed
    self.scoped_courses.to_set - self.needed_scoped_courses(remaining_competences)
  end


  # Returns a set of scoped_courses that are needed by the given competences
  # competences: a collection of competence objects
  def needed_scoped_courses(competences)
    # Make a list of scoped_courses that are needed by remaining profiles
    needed_scoped_courses = Set.new
    competences.each do |competence|
      needed_scoped_courses.merge(competence.recursive_prereqs.where(:type => 'ScopedCourse').all)
    end

    # Add manually added scoped_courses to the list
    needed_scoped_courses.merge(self.extra_scoped_courses)
  end

end
