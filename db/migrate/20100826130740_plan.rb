class Plan < ActiveRecord::Migration
  def self.up
    add_column :users, :curriculum_id, :integer
    
    # Courses that user has selected
    create_table :user_courses do |t|
      t.references :user,            :null => false
      t.references :abstract_course, :null => false
      t.references :course_instance
      t.integer :grade
    end
    add_index(:user_courses, :user_id)
    
    # Profiles that user has selected
    create_table :user_profiles, :id => false do |t|
      t.references :user,    :null => false
      t.references :profile, :null => false
    end
    add_index(:user_profiles, :user_id)
    
  end

  def self.down
    drop_table :user_profiles
    drop_table :user_courses
    remove_column :users, :curriculum_id
  end
end
