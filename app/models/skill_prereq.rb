class SkillPrereq < ActiveRecord::Base

  belongs_to :skill
  belongs_to :prereq, :class_name => 'Skill', :foreign_key => 'prereq_id'

  belongs_to :term

end
