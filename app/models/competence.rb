# Competence, e.g. Steel structures
class Competence < CompetenceNode

  belongs_to :curriculum

  # Parent
  belongs_to :parent_competence,
           :class_name => 'Competence'

  validate :validate_parent_competence_not_a_self_reference

  has_many :children, :class_name => 'Competence', :foreign_key => 'parent_competence_id'
  

  # Descriptions
  has_many :competence_descriptions,
           :dependent   => :destroy,
           :order => 'locale'
  
  has_one  :localized_description, :class_name => "CompetenceDescription",
           :conditions => proc { "locale = '#{I18n.locale}'" }
  
  accepts_nested_attributes_for :competence_descriptions

  # Study plans in which the competence is included
  has_many :plan_competences

  has_many :study_plans_included_in,
           :class_name  => 'StudyPlan',
           :through     => :plan_competences,
           :source      => :study_plan


  # Users that have included this competence in their study plan and therefore plan to study it.
  has_many :users_that_have_planned,
           :class_name  => 'User',
           :through     => :study_plans_included_in,
           :source      => :user

  def courses
    # TODO: get rid of this
    self.prereqs.where(:type => 'ScopedCourse')
  end
  
  #def courses_recursive
    # TODO: get rid of this
  #  self.recursive_prereqs.where(:type => 'ScopedCourse')
  #end
  
  # Returns all courses' ids, recursively
  def course_ids_recursive
    #courses_recursive.map { |course| course.id }
    self.recursive_prereqs.where(:type => 'ScopedCourse').map { |course| course.id }
  end

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

  # Returns a hash {course => [skills]}
  def contributing_skills
    courses = {}  # {course_id => course}
    result = {}   # {course => {skill_id => skill}}

    # Load courses
    competence.recursive_prereqs.where(:type => 'ScopedCourse').find_each do |course|
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


private

  def validate_parent_competence_not_a_self_reference
    if self.parent_competence == self
      errors[:parent_competence] << "Competence cannot refer to itself through 'parent_competence'."
    end
  end

end
