class AddColorToCompetenceNode < ActiveRecord::Migration
  def change
    add_column :skills, :icon, :string
    add_index "skills", ["competence_node_id"]
  end
end
