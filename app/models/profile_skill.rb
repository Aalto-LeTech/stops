# Join model that connect competence profiles to prerequisite skills
class ProfileSkill < ActiveRecord::Base

  belongs_to :profile
  belongs_to :skill
  
end
