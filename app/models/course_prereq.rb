# Join model that connects courses to courses (prerequisites)
class CoursePrereq < ActiveRecord::Base
  self.table_name = "course_prereqs_cache"

  belongs_to :course, :class_name => 'ScopedCourse', :foreign_key => 'scoped_course_id'
  belongs_to :prereq, :class_name => 'ScopedCourse', :foreign_key => 'scoped_prereq_id'
  
end
