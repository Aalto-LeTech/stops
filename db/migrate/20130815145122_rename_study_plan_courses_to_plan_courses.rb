class RenameStudyPlanCoursesToPlanCourses < ActiveRecord::Migration
  def up
    rename_table :study_plan_courses, :plan_courses
    # cli
    # mfsreplace -d app/ script/ -r "studyplancourse" "plancourse" -r "study_plan_course" "plan_course" -r "study plan course" "plan course" -r "StudyPlanCourse" "PlanCourse" -r "studyPlanCourse" "planCourse"
  end

  def down
    rename_table :plan_courses, :study_plan_courses
  end
end
