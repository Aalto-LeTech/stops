class Plan < ActiveRecord::Migration
  def self.up
    add_column :users, :curriculum_id, :integer
    
    # Courses that user has selected
    create_table :user_courses do |t|
      t.references :user
      t.references :course
      t.integer :grade
    end
    
    # Profiles that user has selected
    create_table :user_profiles, :id => false do |t|
      t.references :user
      t.references :profile
    end
    
  end

  def self.down
    drop_table :user_profiles
    drop_table :user_courses
    remove_column :users, :curriculum_id
  end
end
