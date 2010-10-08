class Skill < ActiveRecord::Base
  belongs_to :scoped_course #, :foreign_key => 'course_code', :primary_key => 'code'

  has_many :skill_descriptions, :dependent => :destroy
  
  has_many :skill_prereqs, :dependent => :destroy
  has_many :prereqs, :through => :skill_prereqs, :source => :prereq, :order => 'position'
  
  # Skills for which this is a prerequisite
  has_many :skill_prereq_to, :class_name => 'SkillPrereq', :foreign_key => :prereq_id
  has_many :prereq_to, :through => :skill_prereq_to, :source => :skill, :order => 'position', :conditions => "requirement = #{STRICT_PREREQ}"
  
  def description(locale)
    description = SkillDescription.where(:skill_id => self.id, :locale => locale.to_s).first
    description ? description.description : ''
  end
  
end
