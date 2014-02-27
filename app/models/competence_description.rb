# Internationalized description of Competence
class CompetenceDescription < ActiveRecord::Base
  belongs_to :competence
  belongs_to :term
end
