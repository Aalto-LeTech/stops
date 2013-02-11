class CompetenceNode < ActiveRecord::Base
  # attr_accessible :title, :body

  has_and_belongs_to_many :skills, :autosave => true

  before_destroy :delete_skills_about_to_be_orphaned

  def delete_skills_about_to_be_orphaned
    # Find all skills of the CompetenceNode that are not linked to any other CompetenceNode
    skills_to_be_destroyed = self.skills.joins(<<-SQL
      INNER JOIN (
        SELECT skill_id FROM competence_nodes_skills 
        GROUP BY competence_nodes_skills.skill_id
        HAVING COUNT(competence_node_id) = 1 
      ) AS singly_referred_skills ON skills.id = singly_referred_skills.skill_id
      SQL
    )

    skills_to_be_destroyed.destroy_all
  end
end
