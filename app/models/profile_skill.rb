# Join model that connect competence profiles to prerequisite skills
class ProfileSkill < ActiveRecord::Base

  belongs_to :profile
  belongs_to :skill
  belongs_to :area
  #belongs_to :prereq, :class_name => 'Skill', :foreign_key => "skill_id"
  
end
