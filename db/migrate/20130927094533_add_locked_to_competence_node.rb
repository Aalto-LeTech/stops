class AddLockedToCompetenceNode < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :locked, :boolean, :null => false, :default => false
  end
end
