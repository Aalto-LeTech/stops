class SkillAssociationChanges < ActiveRecord::Migration
  # Changes Skill to be associated with exactly one CompetenceNodes
  # instead of several. The connection of a Skill to all other CompetenceNodes
  # should be handled through a (unimplemented) 'AbstractSkill' model to which 
  # Skill should 'belongs_to'.

  def up
    add_column :skills, :competence_node_id, :integer, :null => false
    drop_table :competence_nodes_skills
  end

  def down
    remove_column :skills, :competence_node_id

     # HABTM-table
    create_table :competence_nodes_skills do |t|
      t.integer :competence_node_id
      t.integer :skill_id
    end
  end
end
