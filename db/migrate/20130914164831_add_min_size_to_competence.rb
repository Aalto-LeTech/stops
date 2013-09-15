class AddMinSizeToCompetence < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :min_credits, :integer
    add_column :abstract_courses, :min_credits, :integer
    add_column :abstract_courses, :max_credits, :integer
    
    add_index "skill_descriptions", "skill_id"
  end
end
