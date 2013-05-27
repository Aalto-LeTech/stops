class Skill < ActiveRecord::Base
  has_many :skill_descriptions, :dependent => :destroy

  has_one :description_with_locale,
          :class_name => "SkillDescription", 
          :conditions => proc { "skill_descriptions.locale = '#{I18n.locale}'" }
  alias :localized_description :description_with_locale

  has_many :skill_prereqs, :dependent => :destroy

  has_many :strict_skill_prereqs,
           :conditions  => { :requirement => "#{STRICT_PREREQ}" },
           :class_name  => 'SkillPrereq'

  has_many :supporting_skill_prereqs,
           :conditions  => { :requirement => "#{SUPPORTING_PREREQ}" },
           :class_name  => 'SkillPrereq'

  has_many :prereqs, 
           :through   => :skill_prereqs, 
           :source    => :prereq, 
           :order     => 'position'

  has_many :strict_prereqs, 
           :through     => :strict_skill_prereqs, 
           :source      => :prereq                 # TODO: :order => 'position',

  has_many :supporting_prereqs, 
           :through     => :supporting_skill_prereqs, 
           :source      => :prereq, 
           :order       => 'position' 

  # Skills for which this is a prerequisite
  has_many :skill_prereq_to, 
           :class_name  => 'SkillPrereq', 
           :foreign_key => :prereq_id, 
           :dependent   => :destroy

  has_many :prereq_to, 
           :through     => :skill_prereq_to, 
           :source      => :skill, 
           :order       => 'position', 
           :conditions  => "requirement = #{STRICT_PREREQ}"

  belongs_to :competence_node

  accepts_nested_attributes_for :skill_descriptions
  
  before_create :assign_valid_position
  before_destroy :shift_skill_positions

  def assign_valid_position
    self.position = Skill.where(:competence_node_id => self.competence_node_id).count
  end

  # Shifts skill positions to fill the position previously occupied by the skill being
  # removed.
  def shift_skill_positions
    self.competence_node.skills.where('skills.id != ?', self.id)
                               .where('position > ?', self.position).each do |skill|

      skill.position -= 1
      skill.save!
    end
  end
  

  def description(locale)
    description = SkillDescription.where(:skill_id => self.id, :locale => locale.to_s).first
    description ? description.description : ''
  end

  def is_prereq_to?(skill_id)
    prereq_found = false
    self.prereq_to.each do |prereq|
      prereq_found = true if prereq.id == skill_id
    end
    prereq_found
  end

  # Calculates study paths from this skill to the skills of the given competence
  # Returns a hash where keys are the skill_ids of the competence skills, and values are arrays of skills on the study paths.
  def path_to_competence(competence)
    target_skill_ids = competence.skill_ids

    # Make a hash of course_ids that belong to the competence
    course_ids = {}
    competence.courses_recursive.each do |scoped_course|
      course_ids[scoped_course.id] = true
      puts scoped_course.id
    end

    paths = {}
    visited = {}
    prereq_to.each do |skill|
      skill.dfs(paths, [], {}, target_skill_ids, course_ids, visited)
    end
    paths
  end

  # paths: collects shortest paths
  # path: array that keeps track of the route that lead to this node
  # path_lengths: keeps track of path_lengths
  # target_skill_ids: when a skill that is included in the target_skill_ids is encountered, current path is added to paths
  # course_ids: DFS does not proceed to courses that are not included in the course_ids hash
  def dfs(paths, path, path_lengths, target_skill_ids, course_ids, visited)
    # If this skill belongs to a course that does not belong to the profile, kill this branch
    if (self.competence_node.type == 'ScopedCourse' && !course_ids.has_key?(self.competence_node_id)) || visited.has_key?(self.id)
      puts "#{self.competence_node.name('fi')} not included"
      return
    end

    # Visit node
    visited[self.id] = true

    if target_skill_ids.include?(self.id) && (!path_lengths[self.id] || path.size < path_lengths[self.id])
      #puts "Reached target: #{self.description('fi')}. Path size: #{path.size}"

      paths[self] = path.clone
      #paths[self.id] << self
      path_lengths[self.id] = path.size
    end

    # Visit each neighbor
    prereq_to.each do |skill|
      path.push(self)
      skill.dfs(paths, path, path_lengths, target_skill_ids, course_ids, visited)
      path.pop
    end
  end

   # Returns all recursive prerequisite skills grouped by courses
   # Returns a hash {course => {skill_id => skill}}
  def contributing_skills
    courses = {}  # {course_id => course}
    result = {}   # {course => {skill_id => skill}}

    # Load courses
#     courses_recursive.each do |course|
#       result[course] = {}
#       courses[course.id] = course
#     end

    stack = []

    self.strict_prereqs.includes(:competence_node).each do |prereq|
      stack.push prereq
    end


    # Run DFS for skills to construct an array of skills that make the competence
    while skill = stack.pop

      if skill.competence_node.type == 'ScopedCourse'
        # Load course if it has not been loaded
        courses[skill.competence_node_id] ||= skill.competence_node

        course = courses[skill.competence_node_id]
        result[course] = {} unless result[course]
        result[course][skill.id] = skill
      end

      # Push neighbors to stack
      skill.strict_prereqs.includes(:competence_node).each do |prereq|
        stack.push prereq
      end
    end

    result.sort_by {|course, skills| course.course_code}
  end

end
