# Join model that connects courses to courses (prerequisites)
class CoursePrereq < ActiveRecord::Base

  belongs_to :course, :class_name => 'ScopedCourse', :foreign_key => 'scoped_course_id'
  belongs_to :prereq, :class_name => 'ScopedCourse', :foreign_key => 'scoped_prereq_id'
  
end
