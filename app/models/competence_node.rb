# CompetenceNode is either ScopedCourse or Competence. It consists of Skills.
class CompetenceNode < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :curriculum

  has_many :skills, 
           :autosave  => true, 
           :dependent => :destroy,
           :order     => :position

  has_many :skill_descriptions,
           :through => :skills

  has_many :localized_skill_descriptions,
           :through     => :skills,
           :class_name  => "SkillDescription",
           :source      => :localized_description
  
  has_many :prereq_skills,
           :through     => :skills,
           :source      => :prereqs
  
  has_many :strict_prereq_skills,
           :through     => :skills,
           :source      => :strict_prereqs

  has_many :supporting_prereq_skills,
           :through     => :skills,
           :source      => :supporting_prereqs

  # Uncached prerequisite nodes
  has_many :uncached_strict_prereq_nodes,
           :through     => :strict_prereq_skills,
           :source      => :competence_node,
           :uniq        => true

  has_many :uncached_supporting_prereq_nodes,
           :through     => :supporting_prereq_skills,
           :source      => :competence_node,
           :uniq        => true
  
  has_many :uncached_prereq_nodes,
           :through     => :prereq_skills,
           :source      => :competence_node,
           :uniq        => true
  
  
  # actual
    # direct
      # strict
      # supporting
      # all
  
  # cached
    # recursive
      # strict          ancestor
    # direct
      # strict          strict
      # supporting      supporting
      # all
  
  
  # Cached prerequisite nodes
  has_many :node_prereqs,
           :dependent => :destroy
  
  has_many :node_prereq_to,
           :class_name  => 'NodePrereq',
           :foreign_key => :prereq_id

  has_many :prereqs,
           :through => :node_prereqs,
           :source  => :prereq

  has_many :strict_prereqs,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{STRICT_PREREQ}",
           :uniq => true

  has_many :strict_prereq_to,
           :through     => :node_prereq_to,
           :source      => :competence_node,
           :conditions  => "requirement = #{STRICT_PREREQ}",
           :uniq => true
  
  has_many :supporting_prereqs,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{SUPPORTING_PREREQ}",
           :uniq => true

  has_many :recursive_prereqs,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{STRICT_PREREQ} OR requirement = #{ANCESTOR_PREREQ}",
           :uniq => true
  
  has_many :ancestor_prereqs,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{ANCESTOR_PREREQ}",
           :uniq => true
  
  
  
  
  has_many :strict_prereq_courses,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{STRICT_PREREQ} AND type='ScopedCourse'",
           :order => 'course_code',
           :uniq => true

  has_many :strict_prereq_to_courses,
           :through     => :node_prereq_to,
           :source      => :competence_node,
           :conditions  => "requirement = #{STRICT_PREREQ} AND type='ScopedCourse'",
           :order => 'course_code',
           :uniq => true
  
  has_many :supporting_prereq_courses,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{SUPPORTING_PREREQ} AND type='ScopedCourse'",
           :order => 'course_code',
           :uniq => true

  has_many :recursive_prereq_courses,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "(requirement = #{STRICT_PREREQ} OR requirement = #{ANCESTOR_PREREQ}) AND type='ScopedCourse'",
           :order => 'course_code',
           :uniq => true
  
  has_many :ancestor_prereq_courses,
           :through     => :node_prereqs,
           :source      => :prereq,
           :conditions  => "requirement = #{ANCESTOR_PREREQ} AND type='ScopedCourse'",
           :order => 'course_code',
           :uniq => true


  # Moves skills from the other competence node to this node and deletes the other node
  # other: CompetenceNode
  def merge(other)
    #Skill.where(:competence_node_id => other.id).update_all(:competence_node_id => self.id)
    original_skill_count = self.skills.size
    
    # Remove prerequisite link from here to other
    SkillPrereq.where(:skill_id => self.skill_ids, :prereq_id => other.skill_ids).destroy_all
    
    # Move skills of other to here
    other.skills.each do |skill|
      skill.competence_node_id = self.id
      skill.position += original_skill_count
      skill.save
    end
    
    other.delete
  end


  # Adds a course and its prereqs recursively to the given courses collection.
  def collect_recursive_strict_prereqs(hash)
    # Do not follow branches that have already been handled
    return if hash.has_key?(self.id)

    # Add this course to the list
    hash[self.id] = self

    # Add pereqs of this course to the list
    uncached_strict_prereq_nodes.each do |prereq|
      prereq.collect_recursive_strict_prereqs(hash)
    end
  end

  # Updates the prerequirement course cache.
  # The cache is a table behind the 'prereqs' variable that provides easy access to all the prerequirement courses which provide at least one competence that is a prerequirement for this course.
  def update_prereqs_cache
    NodePrereq.where(:competence_node_id => self.id).delete_all
    
    # Collect strict prereqs
    nodes = Hash.new
    self.uncached_strict_prereq_nodes.each do |direct_prereq|
      NodePrereq.create(:competence_node => self, :prereq => direct_prereq, :requirement => STRICT_PREREQ)
      
      direct_prereq.uncached_strict_prereq_nodes.each do |prereq|
        prereq.collect_recursive_strict_prereqs(nodes)
      end
    end

    # Add strict prereqs
    nodes.each_value do |prereq|
      NodePrereq.create(:competence_node => self, :prereq => prereq, :requirement => ANCESTOR_PREREQ)
    end
    
    # Collect supporting prereqs
    self.uncached_supporting_prereq_nodes.each do |prereq|
      NodePrereq.create(:competence_node => self, :prereq => prereq, :requirement => SUPPORTING_PREREQ)
    end
  end
  
  # Returns all courses and their prereqs, recursively
#   def courses_recursive
#     courses = Hash.new
# 
#     self.strict_prereqs.each do |prereq|
#       add_course(courses, prereq)
#     end
# 
#     courses.values
#   end
  
  # Adds a course and its prereqs recursively to the given courses collection.
#   def add_course(courses, course)
#     # Do not follow branches that have already been handled
#     return if courses.has_key?(course.id)
# 
#     # Add this course to the list
#     courses[course.id] = course
# 
#     # Add pereqs of this course to the list
#     course.strict_prereqs.each do |prereq|
#       self.add_course(courses, prereq)
#     end
#   end
  
end
