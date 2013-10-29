class AddSupportingRegexToCompetences < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :supporting_regex, :text
  end
end
