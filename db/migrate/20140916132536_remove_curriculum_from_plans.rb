class RemoveCurriculumFromPlans < ActiveRecord::Migration
  def up
    remove_column :study_plans, :curriculum_id
  end

  def down
    add_column :study_plans, :curriculum_id, :integer, :null => false
  end
end
