class TempCourse < ActiveRecord::Base
  belongs_to :curriculum
  
  attr_accessible :alternatives, :assignments, :changing_topic, :code, :contact, :content, :credits, :department, :grading_scale, :grading_details, :graduate_course, :instructors, :language, :materials, :name_en, :name_fi, :name_sv, :other, :outcomes, :period, :prerequisites, :replaces
  
end
