# Internationalized description of skill
class SkillDescription < ActiveRecord::Base
  belongs_to :skill
  belongs_to :term
end
