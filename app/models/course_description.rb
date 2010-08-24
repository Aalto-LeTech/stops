class CourseDescription < ActiveRecord::Base
  belongs_to :course, :foreign_key => 'course_code', :primary_key => 'code'
end
