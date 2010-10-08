class CourseInstance < ActiveRecord::Base

  belongs_to :abstract_course
  belongs_to :period
  
end
