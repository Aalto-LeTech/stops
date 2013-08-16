class StudyPlanCompetence < ActiveRecord::Base

  belongs_to :study_plan
  belongs_to :competence

  #after_validation :add_course_dependency_ids, :on => :create
  #before_destroy :remove_course_dependencies_from_study_plan

  def add_course_dependency_ids
    # Fetch the course ids that are needed by the skills of this competence
    courses = self.competence.courses_recursive
    ids = courses.map { |course| course.id  }

    study_plan = self.study_plan

    # Add Courses to plan courses
    courses.each do |course|
      study_plan.scoped_courses.add_or_increment_ref_count course
    end

    self.included_scoped_course_ids = ids

  end


  def remove_course_dependencies_from_study_plan
    course_ids = self.included_scoped_course_ids

    study_plan = self.study_plan

    StudyPlanCompetence.transaction do
      course_ids.each do |id|
        study_plan.scoped_courses.remove_or_decrement_ref_count :id => id

      end
    end
  end
end
