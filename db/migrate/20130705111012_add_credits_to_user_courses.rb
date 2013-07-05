class AddCreditsToUserCourses < ActiveRecord::Migration
  def change
    add_column :user_courses, :credits, :float
    add_column :study_plan_courses, :credits, :float
  end
end
