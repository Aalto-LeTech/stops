class Skill < ActiveRecord::Base
  belongs_to :course #, :foreign_key => 'course_code', :primary_key => 'code'

  has_many :skill_prereqs
  has_many :prereqs, :through => :skill_prereqs, :source => :prereq, :order => 'position'
  
  # Skills for which this is a prerequisite
  has_many :skill_prereq_to, :class_name => 'SkillPrereq', :foreign_key => :prereq_id
  has_many :prereq_to, :through => :skill_prereq_to, :source => :skill, :order => 'position', :conditions => "requirement = #{STRICT_PREREQ}"
  
  def description(locale)
    description = SkillDescription.find(:first,  :conditions => { :skill_id => self.id, :locale => locale.to_s })
    description ? description.description : ''
  end
  
end
