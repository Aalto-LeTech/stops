class AddGradeToStudyPlanCourses < ActiveRecord::Migration
  def change
    add_column :study_plan_courses, :grade, :integer
  end
end
