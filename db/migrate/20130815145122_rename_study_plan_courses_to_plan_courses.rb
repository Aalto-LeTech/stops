class RenameStudyPlanCoursesToPlanCourses < ActiveRecord::Migration
  def up
    rename_table :study_plan_courses, :plan_courses
    # cli
    # mfsreplace -d app/ script/ -r "studyplancourse" "plancourse" -r "study_plan_course" "plan_course" -r "study plan course" "plan course" -r "StudyPlanCourse" "PlanCourse" -r "studyPlanCourse" "planCourse"
    # mfsreplace -d app/ script/ -r "scopedcourse" "course" -r "scoped_course" "course" -r "scoped course" "course" -r "ScopedCourse" "Course" -r "scopedCourse" "course"
  end

  def down
    rename_table :plan_courses, :study_plan_courses
  end
end
