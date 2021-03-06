# Update exception class for the update_from_json method
class UpdateException < Exception
end

class StudyPlan < ActiveRecord::Base
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
            :source => :abstract_course

  has_many  :scoped_courses,
            :through => :plan_courses,
            :source => :scoped_course
            #:extend => RefCountExtension

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
  
  
  # Returns a summary of study plan as JSON. No caching is performed.
  # {
  #   competences: [
  #     {competence_node_id: 1}
  #   ]
  #   courses: [
  #     {
  #      competence_node_id:
  #      abstract_course_id: 
  #      period_id:
  #      length: 
  #      grade
  #     }
  #   ]
  # }
  def json_summary
    competences = Competence.where('id IN (?) OR parent_competence_id IN (?)', self.competence_ids, self.competence_ids)
    plan_courses = self.plan_courses.includes({:abstract_course => :localized_description})
    
    competences_json = competences.select('competence_nodes.id, supporting_regex')
      .as_json(:root => false)
      
    courses_json = plan_courses.as_json(
        :only => [:scoped_course_id, :abstract_course_id, :competence_node_id, :period_id, :credits, :length, :grade],
        :include => [
          {
            :abstract_course => {
              :only => [:code],
              :methods => [:localized_name]
            }
          }
        ],
        :root => false
      )
    
    response_data = {
      'competences' => competences_json,
      'courses' => courses_json,
    }

    response_data
  end
  
  def json_plan
    periods = self.periods.includes(:localized_description)
    competences = self.competences.includes([:localized_description])
    plan_courses = self.plan_courses.includes({:abstract_course => :localized_description})
    
    periods_data = periods.as_json(
      only: [:id, :begins_at, :ends_at],
      methods: [:localized_name],
      root: false
    )
    
    # TODO: Replace courses_recursive with a more efficient solution
    competences_data = competences.as_json(
      only: [:id],
      methods: [:localized_name, :abstract_prereq_ids],
      root: false
    )

    # TODO: only load relevant course_instances
    plan_courses_data = plan_courses.as_json(
      only: [:id, :abstract_course_id, :competence_node_id, :period_id, :credits, :length, :grade],
      include: [
        {
          abstract_course: {
            only: [:code, :min_credits, :max_credits],
            methods: [:localized_name],
            include: {
              localized_description: {
                only: [:content, :noppa_url, :oodi_url, :default_period, :period_info]
              }
            }
          }
        },
      ],
      root: false
    )

    response_data = {
      periods: periods_data,
      plan_courses: plan_courses_data,
      competences: competences_data
    }
    
    response_data
  end
  
  def json_schedule
    periods = self.periods.includes(:localized_description)
    competences = self.competences.includes([:localized_description])
    plan_courses = self.plan_courses
#     abstract_courses = self.abstract_courses.includes([:localized_description, :course_instances])
    
#     .includes(
#       [
#         abstract_course: [:localized_description, :course_instances],
#         scoped_course: [:strict_prereqs]
#       ]
#     )

    periods_data = periods.as_json(
      only: [:id, :begins_at, :ends_at],
      methods: [:localized_name],
      root: false
    )

    # TODO: Replace courses_recursive with a more efficient solution
    competences_data = competences.as_json(
      only: [:id],
      methods: [:localized_name, :abstract_prereq_ids],
      root: false
    )

    # TODO: only load relevant course_instances
    plan_courses_data = plan_courses.as_json(
      only: [:id, :abstract_course_id, :period_id, :credits, :length, :grade],
      methods: [:abstract_prereq_ids],
      include: [
        {
          abstract_course: {
            only: [:code, :min_credits, :max_credits, :bloom_level],
            methods: [:localized_name],
            include: {
              localized_description: {
                only: [:period_info]
              },
              course_instances: {
                only: [:period_id, :length]
              }
            }
          }
        },
      ],
      root: false
    )

    response_data = {
      periods: periods_data,
      plan_courses: plan_courses_data,
      #abstract_courses: abstract_courses_data,
      competences: competences_data,
    }
    
    response_data
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
  def add_scoped_courses_from_json(scoped_course_ids_to_add_json)
    feedback = {}

    scoped_course_ids_to_add_json.each do |scoped_course_id|
      fdbck = self.add_course(scoped_course_id.to_i, is_manually_added=true)
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
  def remove_plan_courses_from_json(plan_course_ids_to_remove_json)
    feedback = {}

    plan_course_ids_to_remove_json.each do |plan_course_id|
      status = self.remove_plan_course(plan_course_id.to_i)
      if status == :ok
        feedback[plan_course_id] = true
      else
        feedback[plan_course_id] = false
      end
    end

    return feedback
  end


  # Updates the plan's plan_courses
  # plan_data:
  # [
  #   {"plan_course_id": 71, "period_id": 1, "course_instance_id": 45},
  #   {"plan_course_id": 35, "period_id": 2},
  #   {"plan_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
  #   {"plan_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
  #   ...
  # ]
  def update_plan_courses_from_json(plan_data)
    feedback = {}  # plan_course_id => boolean (accepted?)

    # Index information by plan_course_id
    new_course_data = {}  # plan_course_id => {data}
    plan_data.each do |plan_course_data|
      next unless plan_course_data
      
      plan_course_id = plan_course_data['plan_course_id']
      if plan_course_id
        new_course_data[plan_course_id] = plan_course_data
      end
      # TODO: add new plan courses if not found
    end

    self.plan_courses.each do |plan_course|
      feedback[plan_course.id] = false  # Initially, mark the update as rejected.

      # Load the data for this plan_course
      plan_course_data = new_course_data[plan_course.id]
      next unless plan_course_data

      begin
        # Fetch the available course instance if available
        abstract_course_id = plan_course.abstract_course_id
        
        course_instance = nil
        if plan_course_data['period_id']
          # FIXME: This is really slow
          course_instance = CourseInstance.where(abstract_course_id: abstract_course_id, period_id: plan_course_data['period_id']).first
        end

        # Determine whether the course should be regarded as 'instance bound'
        if course_instance && course_instance.length == plan_course_data['length']
          plan_course['course_instance_id'] = course_instance.id
        end

        # Determine whether the course should be regarded as customized
        #new_custom = scoped_course.credits != new_credits

        changed = false
        [:period_id, :course_instance_id, :competence_node_id, :length, :credits, :grade, :custom].each do |variable|
          if plan_course_data.has_key?(variable.to_s)
            new_value = plan_course_data[variable.to_s]
            if plan_course[variable] != new_value
              plan_course[variable] = new_value
              changed = true
            end
          end
        end
        # TODO: new_course_instance_id
        
        # Save possible changes to the plan_course
        plan_course.save if changed

        feedback[plan_course.id] = true
      end
    end

    # Return the dict of accepted plan_courses_to_update.
    return feedback
  end


  # Updates the plan according to the data received
  # Expects a JSON coded array of form:
  # [
  #   {"plan_course_id": 71, "period_id": 1, "course_instance_id": 45},
  #   {"plan_course_id": 35, "period_id": 2},
  #   {"plan_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
  #   {"plan_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
  #   ...
  # ]
  def update_from_json(json)
    feedback = {}

    # if json.has_key?('scoped_course_ids_to_add')
    #   feedback['scoped_course_ids_to_add'] = self.add_scoped_courses_from_json( json['scoped_course_ids_to_add'] )
    # end
    # 
    # if json.has_key?('plan_course_ids_to_remove')
    #   feedback['plan_course_ids_to_remove'] = self.remove_plan_courses_from_json( json['plan_course_ids_to_remove'] )
    # end

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

  # TODO: rename to has_competence_node?
  def has_competence?(competence_node)
    if competence_node.is_a? Competence
      return competences.include? competence_node
    elsif competence_node.is_a? ScopedCourse
      scoped_courses.include? competence_node
    end
    
    return false
  end

  def has_abstract_course?(abstract_course_id)
    abstract_course_ids.include?(abstract_course_id)
  end
  
  def add_competence(competence)
    # Dont't do anything if the study plan already has this competence
    return if has_competence?(competence)

    competences << competence

    # Calculate the scoped_courses to add
    required_courses = competence.recursive_prereq_courses.all
    
    existing_courses = {}  # abstract_course_id => boolean
    self.abstract_course_ids.each do |abstract_course_id|
      existing_courses[abstract_course_id] = true
    end
    
    # Make a list of courses that are not yet in plan
    scoped_courses_to_add = []
    required_courses.each do |scoped_course|
      scoped_courses_to_add << scoped_course unless existing_courses[scoped_course.abstract_course_id] 
    end
    
    #scoped_courses_to_add = required_courses - self.scoped_courses

    scoped_courses_to_add.each do |scoped_course|
      begin
        self.add_course(scoped_course.abstract_course, {
          :competence_node_id => competence.id,
          :scoped_course_id => scoped_course.id
        })
      rescue Exception => e
        logger.error "Failed to add competence #{competence.id}\n" + e.to_s
      end
    end
  end

  # Removes the given competence and courses that are needed by it. Courses that are still needed by the remaining competences, are not removed. Also, manually added courses are not reomved.
  def remove_competence(competence)
    # Remove competence
    competences.delete(competence)

    # Remove courses
    needed_scoped_course_ids = needed_scoped_courses(self.competences).map {|scoped_course| scoped_course.id}
    
    self.plan_courses.each do |plan_course|
      if plan_course.scoped_course_id && !needed_scoped_course_ids.include?(plan_course.scoped_course_id)
        plan_course.destroy
      end
    end
    
    # Reset grouping
    PlanCourse.where(:study_plan_id => self.id, :competence_node_id => competence.id).update_all(:competence_node_id => nil)
  end

  # Adds the scoped course into the study plan
  def add_course(abstract_course, options = {})
    plan_course = PlanCourse.new(
      :study_plan_id       =>  self.id,
      :abstract_course_id  =>  abstract_course.id,
      :credits             =>  abstract_course.min_credits,
    )
    plan_course.competence_node_id = options[:competence_node_id] if options[:competence_node_id]
    plan_course.scoped_course_id = options[:scoped_course_id] if options[:scoped_course_id]
    plan_course.manually_added = true if options[:manually_added]
    plan_course.save
 
    return plan_course
  end

  def remove_scoped_course(scoped_course_id)
    plan_course = self.plan_courses.find_by_scoped_course_id(scoped_course_id)
    return :not_found unless plan_course
    
    plan_course.destroy

    return :ok
  end
  
  def remove_abstract_courses(abstract_course_id)
    self.plan_courses.where(:abstract_course_id => abstract_course_id).delete_all
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

    # Make a list of scoped_courses that aren't needed
    self.scoped_courses.to_set - self.needed_scoped_courses(remaining_competences)
  end


  # Returns a Set of ScopedCourses that are needed by the given competences
  # competences: a collection of Competence objects
  def needed_scoped_courses(competences)
    # Make a list of scoped_courses that are needed by the given competences
    needed_scoped_courses = Set.new
    competences.each do |competence|
      needed_scoped_courses.merge(competence.recursive_prereq_courses.all)
    end
    
    # Add manually added scoped_courses to the list
    needed_scoped_courses.merge(self.extra_scoped_courses)
  end

end
