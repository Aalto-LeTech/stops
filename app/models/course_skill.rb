# Join model that connects ScopedCourses to Skills (prerequisites)
class CourseSkill < ActiveRecord::Base

  belongs_to :scoped_course
  belongs_to :skill, :dependent => :destroy
 
end
