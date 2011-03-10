class Plan < ActiveRecord::Migration
  def self.up
    add_column :users, :curriculum_id, :integer
    
    # Courses that user has selected
    create_table :user_courses do |t|
      t.references :user,            :null => false
      t.references :scoped_course,   :null => false
      t.references :course_instance
      t.boolean :manually_added, :default => false
      t.integer :grade
    end
    add_index(:user_courses, :user_id)
    
    # Profiles that user has selected
    create_table :user_competences, :id => false do |t|
      t.references :user,    :null => false
      t.references :competence, :null => false
    end
    add_index(:user_competences, :user_id)
    
  end

  def self.down
    drop_table :user_competences
    drop_table :user_courses
    remove_column :users, :curriculum_id
  end
end
