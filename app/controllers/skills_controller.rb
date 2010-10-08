class SkillsController < ApplicationController
  
  before_filter :load_curriculum
  
  def prereqs
    @skill = Skill.find(params[:id])
    
    render(:update) do |page|
      page.replace_html 'skill-prereqs', :partial => 'details'
    end 

    #render :partial => 'details'
  end
  
  def future
    @skill = Skill.find(params[:id])
    
    render(:update) do |page|
      page.replace_html 'skill-future', :partial => 'future'
    end 
  end
  
end
