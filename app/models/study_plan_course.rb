# Join model that connects study plan to a course
class StudyPlanCourse < ActiveRecord::Base

  belongs_to :study_plan
  belongs_to :scoped_course
  belongs_to :course_instance
  belongs_to :period

end
