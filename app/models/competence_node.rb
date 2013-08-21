# CompetenceNode is either ScopedCourse or Competence. It consists of Skills.
class CompetenceNode < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :curriculum

  has_many :skills, 
           :autosave  => true, 
           :dependent => :destroy,
           :order     => :position

  # Moves skills from the other competence node to this node and deletes the other node
  # other: CompetenceNode
  def assimilate(other)
    #Skill.where(:competence_node_id => other.id).update_all(:competence_node_id => self.id)
    original_skill_count = self.skills.size
    
    # Remove prerequisite link from here to other
    SkillPrereq.where(:skill_id => self.skill_ids, :prereq_id => other.skill_ids).destroy_all
    
    # Move skills of other to here
    other.skills.each do |skill|
      skill.competence_node_id = self.id
      skill.position += original_skill_count
      skill.save
    end
    
    other.delete
  end
  
end
