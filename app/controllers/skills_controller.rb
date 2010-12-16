class SkillsController < ApplicationController
  
  #before_filter :load_curriculum
  
  layout nil
  
  def prereqs
    @skill = Skill.find(params[:id])
    
    render 'prereqs'
  end
  
  def future
    @skill = Skill.find(params[:id])
    
    render 'future'
  end

  
  def profilepath
    skill = Skill.find(params[:id])
    profile = Profile.find(params[:profile_id])
    
    @paths = skill.path_to_profile(profile)
    
    render 'profilepath', :paths => @paths
  end
  
end
