# Join model that connects study plan to a course
class StudyPlanCourse < ActiveRecord::Base

  belongs_to :study_plan
  belongs_to :scoped_course
  # belongs_to :course_instance  C20130619
  belongs_to :period

end
