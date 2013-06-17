class MoveColumnsBetweenUserAndStudyPlan < ActiveRecord::Migration
  def up
    StudyPlan.delete_all
    add_column :study_plans, :curriculum_id, :integer, :null => false
    # no need to copy curriculum ids because no such data exists in the database
    remove_column :users, :curriculum_id
    remove_column :study_plan_courses, :grade

    create_table 'user_courses', :force => true do |t|
      t.integer 'user_id',                              :null => false
      t.integer 'abstract_course_id',                   :null => false
      t.integer 'course_instance_id'
      t.integer 'grade'
    end

    add_index 'user_courses', ['user_id'],     :name => 'index_user_courses_on_user_id'
  end

  def down
    add_column :users, :curriculum_id
    remove_column :study_plans, :curriculum_id

    drop_table :user_courses
  end
end
