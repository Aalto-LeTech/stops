class StudyPlanCompetence < ActiveRecord::Base
  
  belongs_to :study_plan
  belongs_to :competence

  after_validation :add_course_dependency_ids

  def add_course_dependency_ids
    # TODO

  end
end
