class CreateCompetenceNodes < ActiveRecord::Migration
  def up
    # Remove tables to be combined
    drop_table :competences
    drop_table :scoped_courses
    drop_table :profiles

    # Create a new combined table
    create_table :competence_nodes do |t|
      t.string 'type'
      t.integer 'credits'
      t.integer 'profile_id'
      t.integer 'level'
      
      # Columns for ScopedCourse
      t.integer 'abstract_course_id'
      t.integer 'curriculum_id'
      t.string  'course_code'
      t.timestamps
    end

     add_index "competence_nodes", ["profile_id"], :name => "index_competence_nodes_on_profile_id"
     add_index "competence_nodes", ["abstract_course_id", "curriculum_id"], :name => "index_competence_nodes_on_abstract_course_id_and_curriculum_id"
  end


  def down
    create_table :competences do |t|
      t.integer "profile_id",                  :null => false
      t.integer "level",      :default => 1
      t.float   "credits",    :default => 0.0, :null => false
    end

    create_table :scoped_courses do |t|
      t.integer "abstract_course_id", :null => false
      t.integer "curriculum_id",      :null => false
      t.string  "code"
      t.float   "credits"
    end

    create_table :profiles do |t|
      t.integer "curriculum_id", :null => false
    end
    remove_index :competence_nodes, :name => "index_competence_nodes_on_profile_id"
    remove_index :competence_nodes, :name => "index_competence_nodes_on_abstract_course_id_and_curriculum_id"
    drop_table :competence_nodes
  end   
end
