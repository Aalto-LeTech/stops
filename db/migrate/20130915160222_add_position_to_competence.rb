class AddPositionToCompetence < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :position, :integer
  end
end
