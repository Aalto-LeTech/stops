class SkillsController < ApplicationController
  
  def details
    @skill = Skill.find(params[:id])
    
    render :partial => 'details'
  end
end
