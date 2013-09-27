class RemovePlanCourseIndex < ActiveRecord::Migration
  def up
    remove_index :plan_courses, :name => 'index_study_plan_courses_on_study_plan_id_and_scoped_course_id'
  end
end
