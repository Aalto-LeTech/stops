class MajorRestructuring < ActiveRecord::Migration

  def up
    add_column :study_plan_courses, :length, :integer
    add_column :study_plan_courses, :custom, :boolean, :default => false
    add_column :study_plans, :first_period_id, :integer
    add_column :study_plans, :last_period_id, :integer
    change_column :course_descriptions, :scoped_course_id, :integer, :null => true
    add_column :study_plan_courses, :abstract_course_id, :integer
    add_column :course_descriptions, :abstract_course_id, :integer

    execute 'UPDATE course_descriptions SET abstract_course_id=competence_nodes.abstract_course_id FROM competence_nodes WHERE course_descriptions.scoped_course_id = competence_nodes.id'

    change_column :course_descriptions, :abstract_course_id, :integer, :null => false
    remove_column :course_descriptions, :scoped_course_id
  end

end
