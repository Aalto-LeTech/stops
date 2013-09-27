class RemovePlanCourseConstraint < ActiveRecord::Migration
  def up
    change_column :plan_courses, :scoped_course_id, :integer, :null => true
    change_column :plan_courses, :credits, :float, :null => true
    change_column :competence_nodes, :curriculum_id, :integer, :null => false
    change_column :abstract_courses, :code, :string, :null => false
    change_column :course_instances, :length, :integer, :null => false, :default => 1
  end

  def down
  end
end
