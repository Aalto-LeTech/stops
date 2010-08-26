# Join model that connects users to courses that they have finished
class UserGrades < ActiveRecord::Base

  belongs_to :user
  belongs_to :course
  
end
