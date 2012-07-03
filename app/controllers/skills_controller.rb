class SkillsController < ApplicationController
  
  #before_filter :load_curriculum
    
  def new
    @skill = Skill.new
    
    if params[:competence_id]
      @skill.skillable = Competence.find(params[:competence_id])
    elsif params[:course_id]
      @skill.skillable = Course.find(params[:course_id])
    end
   
    # Create empty descriptions for each required locale
    REQUIRED_LOCALES.each do |locale| 
      @skill.skill_descriptions << SkillDescription.new(:locale => locale)
    end

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

  def add_prereq
    SkillPrereq.create :skill_id     => Integer(params[:id]), 
                       :prereq_id    => Integer(params[:prereq_id]), 
                       :requirement  => STRICT_PREREQ

    render :nothing => true
  end

  def remove_prereq
    @prereq = SkillPrereq.where "skill_id = ? AND prereq_id = ?", 
                params[:id], params[:prereq_id]

    @prereq.first.destroy
    render :nothing => true
  end
  
  def prereqs
    @skill = Skill.find(params[:id])
    
    @prereq_courses = {}
    
    @skill.skill_prereqs.each do |prereq_skill|
      @prereq_courses[prereq_skill.prereq.skillable] = [] unless @prereq_courses[prereq_skill.prereq.skillable]
      @prereq_courses[prereq_skill.prereq.skillable] << prereq_skill
    end
    
    render 'prereqs', :layout => nil
  end
  
  def future
    @skill = Skill.find(params[:id])
    
    @future_courses = {}
    @future_competences = {}
    
    if params[:user_id]
      user = User.find(params[:user_id])
    else
      user = nil
    end
    
    @skill.skill_prereq_to.each do |future_skill|
      if future_skill.skill.skillable_type == 'ScopedCourse' && (!user || user.courses.include?(future_skill.skill.skillable))
        @future_courses[future_skill.skill.skillable] = [] unless @future_courses[future_skill.skill.skillable]
        @future_courses[future_skill.skill.skillable] << future_skill
      elsif future_skill.skill.skillable_type == 'Competence' && (!user || user.competences.include?(future_skill.skill.skillable))
        @future_competences[future_skill.skill.skillable] = [] unless @future_competences[future_skill.skill.skillable_id]
        @future_competences[future_skill.skill.skillable] << future_skill
      end
    end
    
    render 'future', :layout => nil
  end

  
  def competencepath
    skill = Skill.find(params[:id])
    competence = Competence.find(params[:competence_id])
    
    @paths = skill.path_to_competence(competence)
    
    render 'competencepath', :paths => @paths, :layout => nil
  end
  
end
