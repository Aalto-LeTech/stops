class SkillsController < ApplicationController
  
  #before_filter :load_curriculum
  
  layout nil
  
  def new
    @skill = Skill.new
    
    if params[:competence_id]
      @skill.skillable = Competence.find(params[:competence_id])
    elsif params[:course_id]
      @skill.skillable = Course.find(params[:course_id])
    end
    
    @skill.skill_descriptions << SkillDescription.new(:locale => I18n.locale)

    respond_to do |format|
      format.html # new.html.erb
      format.js
      format.xml  { render :xml => @skill }
    end
  end
  
  def edit
    @skill = Skill.find(params[:id])
    
    respond_to do |format|
      format.html
      format.js
      format.xml  { render :xml => @skill }
    end
  end
  
  # POST /skills
  def create
    @skill = Skill.new(params[:skill])
    
    respond_to do |format|
      if @skill.save
        format.html { redirect_to root_path }
        format.js
        format.xml  { render :xml => @skill, :status => :created, :location => @skill }
      else
        format.html { render :action => "new" }
        format.js
        format.xml  { render :xml => @skill.errors, :status => :unprocessable_entity }
      end
    end
  end
  
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
