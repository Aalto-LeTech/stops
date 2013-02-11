class ChangeSkillsAndCompetenceCourses < ActiveRecord::Migration
  def up
    # skills
    remove_column :skills, :skillable_id
    remove_column :skills, :skillable_type

    # HABTM-table
    create_table :competence_nodes_skills do |t|
      t.integer :competence_node_id
      t.integer :skill_id
    end

    # competence_courses
    rename_table :competence_courses, :competence_courses_cache

  end

  def down 
    add_column :skills, :skillable_id, :integer, :null => false
    add_column :skills, :skillable_type, :string, :null => false

    rename_table :competence_courses_cache, :competence_courses
  end
end
