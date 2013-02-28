class AddParentCompetenceToCompetenceNodes < ActiveRecord::Migration
  def up
    add_column :competence_nodes, :parent_competence_id, :integer, :null => true
    remove_column :competence_nodes, :profile_id
  end

  def down
    add_column :competence_nodes, :profile_id, :integer
    remove_column :competence_nodes, :parent_competence_id
  end
end
