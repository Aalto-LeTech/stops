class AddPeriodToCourseInstance < ActiveRecord::Migration
  def up
    add_column :study_plan_courses, :period_id, :integer
  end

  def down
    remove_column :study_plan_courses, :period_id
  end
end
