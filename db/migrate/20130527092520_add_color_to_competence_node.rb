class AddColorToCompetenceNode < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :color, :string
  end
end
