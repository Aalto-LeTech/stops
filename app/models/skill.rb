class Skill < ActiveRecord::Base
  belongs_to :course #, :foreign_key => 'course_code', :primary_key => 'code'

  has_many :skill_prereqs
  has_many :prereqs, :through => :skill_prereqs, :source => :prereq, :order => 'position'
  
  def description(locale)
    description = SkillDescription.find(:first,  :conditions => { :skill_id => self.id, :locale => locale.to_s })
    description ? description.description : ''
  end
  
end
