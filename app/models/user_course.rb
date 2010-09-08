# Join model that connects user to a course
class UserCourse < ActiveRecord::Base

  belongs_to :user
  belongs_to :course
 
end
