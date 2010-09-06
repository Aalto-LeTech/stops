class SkillsController < ApplicationController
  
  before_filter :load_curriculum
  
  def prereqs
    @skill = Skill.find(params[:id])
    
    render :partial => 'details'
  end
  
  def future
    @skill = Skill.find(params[:id])
    
    render :partial => 'future'
  end
  
end
