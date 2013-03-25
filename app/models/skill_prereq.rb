class SkillPrereq < ActiveRecord::Base

  belongs_to :skill
  belongs_to :prereq, :class_name => 'Skill', :foreign_key => 'prereq_id'
 
  validates_numericality_of :requirement, :less_than_or_equal_to => 1
end
