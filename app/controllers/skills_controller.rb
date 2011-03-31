class SkillsController < ApplicationController
  
  #before_filter :load_curriculum
    
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
  
  def edit
    @skill = Skill.find(params[:id])
    
    respond_to do |format|
      format.html
      format.js
      format.xml  { render :xml => @skill }
    end
  end
  
  # PUT /skills/1
  def update
    @skill = Skill.find(params[:id])
    
    if @skill.skillable_type == ScopedCourse
      @curriculum = @skill.skillable.curriculum
    else
      @curriculum = @skill.skillable.profile.curriculum
    end

    respond_to do |format|
      if @skill.update_attributes(params[:skill])
        format.html { redirect_to [@curriculum, @skill.skillable] }
        format.js
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js
        format.xml  { render :xml => @skill.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /skills/1
  def destroy
    @skill = Skill.find(params[:id])
    
    skillable = @skill.skillable
    if @skill.skillable_type == ScopedCourse
      @curriculum = @skill.skillable.curriculum
    else
      @curriculum = @skill.skillable.profile.curriculum
    end
    
    @skill.destroy

    respond_to do |format|
      format.html { redirect_to [@curriculum, skillable] }
      format.xml  { head :ok }
    end
  end
  
  def matrix
    return unless params[:prereqs]
    
    params[:prereqs].each do |prereq_id, row|
      row.each do |skill_id, value|
        new_requirement = false if value == '0'
        new_requirement = SUPPORTING_PREREQ if value == '1'
        new_requirement = STRICT_PREREQ if value == '2'
      
        # Read existing prereq
        existing_prereq = SkillPrereq.where(:skill_id => Integer(skill_id), :prereq_id => Integer(prereq_id)).first
        
        if new_requirement
          if existing_prereq
            # Update existing prereq
            existing_prereq.requirement = new_requirement
            existing_prereq.save
          else
            # Create new prereq
            SkillPrereq.create(:skill_id => Integer(skill_id), :prereq_id => Integer(prereq_id), :requirement => new_requirement)
          end
        else
          # Delete existing prereq
          existing_prereq.destroy
        end
      end
    end
    
  end
  
  def prereqs
    @skill = Skill.find(params[:id])
    
    render 'prereqs', :layout => nil
  end
  
  def future
    @skill = Skill.find(params[:id])
    
    render 'future', :layout => nil
  end

  
  def profilepath
    skill = Skill.find(params[:id])
    profile = Profile.find(params[:profile_id])
    
    @paths = skill.path_to_profile(profile)
    
    render 'profilepath', :paths => @paths, :layout => nil
  end
  
end
