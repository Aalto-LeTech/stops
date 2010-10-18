class SkillsController < ApplicationController
  
  before_filter :load_curriculum
  
  def prereqs
    @skill = Skill.find(params[:id])
    
    render 'prereqs', :skill => @skill

  end
  
  def future
    @skill = Skill.find(params[:id])
    
    render 'future', :skill => @skill
  end
  
end
