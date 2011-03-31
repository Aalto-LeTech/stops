class Curriculums::CompetencesController < CurriculumsController
  
  #before_filter :load_curriculum
  #before_filter :load_profile
  before_filter :load_competence
  
  def load_competence
    @competence = Competence.find(params[:id])
    @profile = @competence.profile
    load_curriculum
  end
  
  # curriculums/1/competences/1
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @competence }
    end
  end

  # GET /competences/1/edit
  def edit
    
    @courses = @curriculum.courses.includes(:skills)
    
    #top = @competence.skills

    @prereqs = {} # hash of hashes, contains SkillPrereq objects, [prereq_id][skill_id]
    
    p = SkillPrereq.where(:skill_id => @competence.skill_ids)
    p.each do |prereq|
      @prereqs[prereq.prereq_id] = {} unless @prereqs[prereq.prereq_id] # Initialize inner hash
      @prereqs[prereq.prereq_id][prereq.skill_id] = prereq
      
      logger.debug "@prereqs[#{prereq.prereq_id}][#{prereq.skill_id}]"
    end
    
    @n_skills = @competence.skills.size
  end

  # PUT /competences/1
  # PUT /competences/1.xml
  def update

    respond_to do |format|
      if @competence.update_attributes(params[:competence])
        format.html { redirect_to @competence }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @competence.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end
