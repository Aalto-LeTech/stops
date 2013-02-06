class ChangeSkillsAndCompetenceCourses < ActiveRecord::Migration
  def up
    # skills
    rename_column :skills, :skillable_id, :competence_node_id
    remove_column :skills, :skillable_type

    # competence_courses
    rename_table :competence_courses, :competence_courses_cache

  end

  def down 
    rename_column :skills, :competence_node_id, :skillable_id
    add_column :skills, :skillable_type, :string, :null => false

    rename_table :competence_courses_cache, :competence_courses
  end
end
