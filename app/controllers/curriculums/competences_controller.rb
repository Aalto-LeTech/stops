class Curriculums::CompetencesController < CurriculumsController

  #before_filter :load_curriculum
  #before_filter :load_profile
  before_filter :load_competence, :except => [:index]

  def index
    load_curriculum
    @competences = Competence.where(:profile_id => @curriculum.profile_ids).joins(:competence_descriptions).where(["competence_descriptions.locale = ?", I18n.locale])

    respond_to do |format|
      format.json { render :json => @competences.select("competences.id, competence_descriptions.name AS translated_name").to_json(:methods => :strict_prereq_ids) } # :skill_ids
    end
  end

  def load_competence
    #if params[:competence_id]
    #  @competence = Competence.find(params[:competence_id])
    #else params[:id]
      @competence = Competence.find(params[:competence_id] || params[:id])
    #end

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

  def contributors
    @courses = @competence.contributing_skills
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

    @competence.refresh_prereq_courses
  end

  # edit_skill_preqreqs.js.erb & _prereq_skills_selection.html.erb
  def edit_skill_prereqs
    respond_to do |format|
      format.html do 
        #render "edit_skill_prereqs.js.erb"

        # Validate query string key
        render :status => 500 unless /^\d+$/ =~ params[:skill_id] 

        @skill = Skill.includes(:description_with_locale).find(params[:skill_id].to_i)

        @skill_id = params[:skill_id]
        render :partial => "prereq_skills_selection"
        # TODO: Render whole the whole view with prereq_skills_selection -partial 
      end 
    end
  end
  

  # Action for retrieving courses that match certain search terms
  # using AJAX.
  def search_skills_and_courses
    # @courses = ScopedCourse.includes(:course_description_with_locale, :skill_descriptions).search_full_text params[:q] 
    
    @courses = ScopedCourse.search params[:q], 
                  :include => [:course_description_with_locale, :skill_descriptions]

    respond_to do |format|
      format.html do
        render :partial => "search_results"
      end 
    end 
  end

  def prereqs
    @competence = Competence.find(params[:id])

    render :action => 'prereqs', :layout => 'fullscreen'
  end
end


