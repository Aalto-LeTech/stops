# Join model that connects competence profiles to prerequisite skills
class CompetenceSkill < ActiveRecord::Base

  belongs_to :competence
  belongs_to :skill, :dependent => :destroy
  
end
