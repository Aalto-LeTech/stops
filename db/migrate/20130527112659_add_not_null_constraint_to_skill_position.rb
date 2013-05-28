class AddNotNullConstraintToSkillPosition < ActiveRecord::Migration
  def up
    Skill.update_all(:position => 0)
    
    # Make sure each CompetenceNode's skills have a position value 
    CompetenceNode.all.each do |node|
      pos = 0
      node.skills.each do |skill|
        skill.position = pos
        pos += 1
        skill.save!
      end
    end

    change_column :skills, :position, :integer, :null => false, :default => 0
  end

  def down
    change_column :skill, :position, :integer, :null => true
  end
end
