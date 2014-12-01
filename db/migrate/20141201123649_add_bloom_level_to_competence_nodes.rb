class AddBloomLevelToCompetenceNodes < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :bloom_level, :integer
  end
end
