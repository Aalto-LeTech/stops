# Competence, e.g. Steel structures, level 1
class Competence < CompetenceNode


  belongs_to :curriculum


  # Parent
  belongs_to :parent_competence,
           :class_name => 'Competence'

  validate :validate_parent_competence_not_a_self_reference

  has_many :contained_competences,
           :foreign_key => :parent_competence_id,
           :class_name  => 'Competence'


  # Descriptions
  has_many :competence_descriptions,
           :dependent   => :destroy,
           :order => 'locale'

  accepts_nested_attributes_for :competence_descriptions

  has_one  :localized_description, :class_name => "CompetenceDescription",
           :conditions => proc { "locale = '#{I18n.locale}'" }


  # Skills
  has_many :skills_ordered,
           :class_name  => 'Skill',
           :foreign_key => :competence_node_id,
           :order       => 'position'


  # Competence courses
  has_many :competence_courses,
           :dependent   => :destroy

  has_many :courses,
           :through     => :competence_courses,
           :source      => :scoped_course


  # Prerequisite courses
  has_many :strict_prerequirement_skills,
           :through     => :skills,
           :source      => :strict_prereqs

  has_many :strict_prereqs,
           :through     => :strict_prerequirement_skills,
           :source      => :competence_node,
           :uniq        => true

  has_many :supporting_prereqs,
           :through     => :competence_courses,
           :source      => :scoped_course,
           :conditions  => "requirement = #{SUPPORTING_PREREQ}"


  # Study plans in which the competence is included
  has_many :study_plan_competences

  has_many :study_plans_included_in,
           :class_name  => 'StudyPlan',
           :through     => :study_plan_competences,
           :source      => :study_plan


  # Users that have included this competence in their study plan and therefore
  # plan to study it.
  has_many :users_that_have_planned,
           :class_name  => 'User',
           :through     => :study_plans_included_in,
           :source      => :user


  def duplicate
    duplicate = self.dup :include => [:competence_descriptions, {:skills => [:skill_descriptions, :skill_prereqs]}]

    duplicate.competence_descriptions.each do |description|
      description.name += ' (copy)'
    end

    duplicate.save()
  end


  def localized_name
    localized_description.nil? ? "" : localized_description.name
  end


  def name(locale)
    throw "Deprecated! use localized_name!"
    description = competence_descriptions.where(:locale => locale.to_s).first
    description ? description.name : ''
  end


  def description(locale)
    throw "Deprecated! use localized_name!"
    description = competence_descriptions.where(:locale => locale.to_s).first
    description ? description.description : ''
  end


  # Returns all courses and their prereqs, recursively
  def courses_recursive
    courses = Hash.new

    self.strict_prereqs.each do |prereq|
      add_course(courses, prereq)
    end

    courses.values
  end


  # Adds a course and its prereqs recursively to the given courses collection. If a course belongs to a prereq cycle, it is added to the cycles collection.
  def add_course(courses, course)
    # Do not follow branches that have already been handled
    return if courses.has_key?(course.id)

    # Add this course to the list
    courses[course.id] = course

    # Add pereqs of this course to the list
    course.strict_prereqs.each do |prereq|
      self.add_course(courses, prereq)
    end
  end


  # Returns all courses' ids, recursively
  def course_ids_recursive
      courses_recursive.map { |course| course.id }
  end


  # Returns a hash {course => [skills]}
  def contributing_skills
    courses = {}  # {course_id => course}
    result = {}   # {course => {skill_id => skill}}

    # Load courses
    courses_recursive.each do |course|
      result[course] = {}
      courses[course.id] = course
    end

    stack = []

    self.skills.each do |skill|
      skill.strict_prereqs.each do |prereq|
        stack.push prereq
      end
    end

    # Run DFS for skills to construct an array of skills that make the competence
    while skill = stack.pop
      # Load course if it has not been loaded

      course = courses[skill.competence_node_id]
      result[course][skill.id] = skill

      # Push neighbors to stack
      skill.strict_prereqs.each do |prereq|
        stack.push prereq
      end
    end

    result.sort_by {|course, skills| course.course_code}
  end


  def refresh_prereq_courses
    prereq_courses = {}  # bag of courses, [course_id]

    # Make a list of prereq courses
    skills.each do |competence_skill|
      competence_skill.prereqs.each do |prereq_skill|
        if prereq_skill.competence_node.type == 'Competence'
          # Competence depends on other competence
          # TODO: raise Exception
          logger.error "Competence depends on competence"
          next
        end

        prereq_course_id = prereq_skill.competence_node_id # Must be a ScopedCourse
        prereq_courses[prereq_course_id] = true

      end
    end

    logger.debug "PREREQ COURSES: #{prereq_courses.keys.inspect}"

    # TODO: Update
    # self.competence_course_ids = prereq_courses.keys

    # TODO: check cycles
  end


private

  def validate_parent_competence_not_a_self_reference
    if self.parent_competence == self
      errors[:parent_competence] << "Competence cannot refer to itself through 'parent_competence'."
    end
  end

end
