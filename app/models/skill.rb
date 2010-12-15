class Skill < ActiveRecord::Base
  belongs_to :scoped_course #, :foreign_key => 'course_code', :primary_key => 'code'

  has_many :skill_descriptions, :dependent => :destroy
  
  has_many :skill_prereqs, :dependent => :destroy
  has_many :prereqs, :through => :skill_prereqs, :source => :prereq, :order => 'position'
  has_many :strict_prereqs, :through => :skill_prereqs, :source => :prereq, :order => 'position', :conditions => "requirement = #{STRICT_PREREQ}"
  
  # Skills for which this is a prerequisite
  has_many :skill_prereq_to, :class_name => 'SkillPrereq', :foreign_key => :prereq_id
  has_many :prereq_to, :through => :skill_prereq_to, :source => :skill, :order => 'position', :conditions => "requirement = #{STRICT_PREREQ}"
  
  def description(locale)
    description = SkillDescription.where(:skill_id => self.id, :locale => locale.to_s).first
    description ? description.description : ''
  end

  # Calculates study paths from this skill to the skills of the given profile
  # Returns a hash where keys are the skill_ids of the profile skills, and values are arrays of skills on the study paths.
  def path_to_profile(profile)
    target_skill_ids = profile.skill_ids
    
    paths = {}
    prereq_to.each do |skill|
      skill.dfs(paths, [], {}, target_skill_ids)
    end
    paths
  end
  
  def dfs(paths, path, path_lengths, target_skill_ids)
    
    # Visit node
    if target_skill_ids.include?(self.id) && (!path_lengths[self.id] || path.size < path_lengths[self.id])
      #puts "Reached target: #{self.description('fi')}. Path size: #{path.size}"
      
      paths[self] = path.clone
      #paths[self.id] << self
      path_lengths[self.id] = path.size
    end
    
    # Visit each neighbor
    prereq_to.each do |skill|
      path.push(self)
      skill.dfs(paths, path, path_lengths, target_skill_ids)
      path.pop
    end
    
    
  end
  
end
