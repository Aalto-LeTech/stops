class CreateVersions < ActiveRecord::Migration
  def up
    create_table :terms do |t|
      t.integer :start_year
      t.integer :end_year
    end
    
    add_column :curriculums, :term_id, :integer
    add_column :competence_nodes, :term_id, :integer
    add_column :skills, :term_id, :integer
    add_column :skill_descriptions, :term_id, :integer
    add_column :skill_prereqs, :term_id, :integer
    
    add_index :competence_nodes, :term_id
    add_index :skills, :term_id
    add_index :skill_descriptions, :term_id
    add_index :skill_prereqs, :term_id
  end

  def down
    drop_table :terms
    
    remove_column :curriculums, :term_id
    remove_column :competence_nodes, :term_id
    remove_column :skills, :term_id
    remove_column :skill_descriptions, :term_id
    remove_column :skill_prereqs, :term_id
  end
end
