# Join model that connects user to a course
class UserCourse < ActiveRecord::Base

  belongs_to :user
  belongs_to :scoped_course
  belongs_to :course_instance
  
end
