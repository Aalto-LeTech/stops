class CoursePrereq < ActiveRecord::Base

  belongs_to :course, :foreign_key => 'course_id'
  belongs_to :prereq, :class_name => 'Course', :foreign_key => 'prereq_id'
  
end
