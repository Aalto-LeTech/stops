class Plan < ActiveRecord::Migration
  def self.up
    add_column :users, :curriculum_id, :integer
    
    create_table :user_courses, :id => false do |t|
      t.references :user
      t.references :course
    end
    
    create_table :user_profiles, :id => false do |t|
      t.references :user
      t.references :profile
    end
    
    # Courses that users have passed
    create_table :user_grades do |t|
      t.references :user
      t.references :course
      t.integer :grade
    end
    
  end

  def self.down
    drop_table :user_grades
    drop_table :user_profiles
    drop_table :user_courses
    remove_column :users, :curriculum_id
  end
end
