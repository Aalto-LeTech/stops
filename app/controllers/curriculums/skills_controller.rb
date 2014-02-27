class Curriculums::SkillsController < CurriculumsController

  before_filter :load_curriculum

  respond_to :json, :only => [:index]

  def index
    # TODO: only load skills that belong to this curriculum
    #.joins(:competence_node), order :competence_node_id
    @skills = Skill
                .includes(:strict_prereqs, :supporting_prereqs, :localized_description)
                .order(:position)
                #.where('competence_nodes.id' => @curriculum.course_ids)

    respond_to do |format|
      #format.html { render :text => @skills.to_json(:include => :strict_prereq_ids) }
      format.xml { render :xml => @skills }
      format.json do
        render :json => @skills.to_json(
          :only => [:id, :competence_node_id],
          :methods => [:strict_prereq_ids, :supporting_prereq_ids, :localized_name],
          :root => true
        )
      end
    end
  end

  # POST /curriculum/:id/skills
  def create
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache

    @skill = Skill.new(params[:skill])
    @skill.term = @curriculum.term
    @skill.skill_descriptions.each { |description| description.term = @curriculum.term }
    @skill.save!

    respond_to do |format|
      format.js {
        render :json => @skill.to_json(:include => [:skill_descriptions], :root => true)
      }
    end
  end

  # PUT /curriculum/:curriculum_id/skills/:id
  def update
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache

    @skill = Skill.find(params[:id])
    @skill.update_attributes(params[:skill])
    
    respond_to do |format|
      format.js {
        render :json => @skill.to_json(:include => [:skill_descriptions], :root => true)
      }
    end
  end

  def update_position
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache
    
    Skill.transaction do
      begin
        skill = Skill.find params[:id]
      rescue ActiveRecord::RecordNotFound
        return render :nothing => true, :status => 500
      end

      if is_non_negative_integer params[:position]
        target = params[:position].to_i
      else
        return render :nothing => true, :status => 500
      end

      current = skill.position
      node_id = skill.competence_node_id

      if current == target || target >= Skill.where(:competence_node_id => node_id).count
        return render :nothing => true
      end

      if current < target
        skills = Skill.where(:competence_node_id => node_id)
                      .where('? < position AND position <= ?', current, target)

        skills.each do |skill|
          skill.position -= 1
          skill.save!
        end
      else # target < current
        skills = Skill.where(:competence_node_id => node_id)
                      .where('? <= position AND position < ?', target, current)

        skills.each do |skill|
          skill.position += 1
          skill.save!
        end
      end

      skill.position = target
      skill.save!

      render :nothing => true
    end
  end

  # DELETE /curriculums/:curriculum_id/skills/:id
  def destroy
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache

    @skill = Skill.find(params[:id])
    node = @skill.competence_node
    @skill.destroy
    
    node.update_prereqs_cache()

    respond_to do |format|
      format.js {
        render :nothing => true
      }
    end
  end

  # POST /curriculums/:curriculum_id/skills/:id/add_prereq
  def add_prereq
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache

    requirement_type = params[:requirement] || STRICT_PREREQ

    # Reset
    SkillPrereq.where(:skill_id => params[:id], :prereq_id => params[:prereq_id]).delete_all

    # Add new
    SkillPrereq.create :skill_id     => Integer(params[:id]),
                       :prereq_id    => Integer(params[:prereq_id]),
                       :requirement  => requirement_type,
                       :term_id      => @curriculum.term_id

    # Update prereq cache
    target_skill = Skill.find(params[:id])
    target_skill.competence_node.update_prereqs_cache()

    render :nothing => true
  end

  # POST /curriculums/:curriculum_id/skills/:id/remove_prereq
  # params: {'prereq_id': prereq_skill_id}
  def remove_prereq
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache
    
    @prereq = SkillPrereq.where "skill_id = ? AND prereq_id = ?",
                params[:id], params[:prereq_id]

    @prereq.all.each do |prereq|
      prereq.destroy
    end
    
    # Update prereq cache
    target_skill = Skill.find(params[:id])
    target_skill.competence_node.update_prereqs_cache()

    render :nothing => true
  end

  # Action for retrieving courses that match certain search terms
  # using AJAX.
  # GET /curriculum/:id/skills/:id/
  def search_skills_and_courses
    # FIXME: this is probably not used any more
    authorize! :update, Skill

    @courses = ScopedCourse.search params[:q],
                  :include  => [:localized_description, :localized_skill_descriptions],
                  :page     => params[:p] || 1, :per_page => 20

    # Validate skill_id!
    render(:nothing => true, :status => 500) unless /^\d+$/ =~ params[:sid]

    skill_id = params[:sid]

    # Query to find out if skills are already prerequirements to the
    # skill being edited.
    queryresults = ActiveRecord::Base.connection.select_all %Q{
      SELECT DISTINCT ON (skills.id) skills.id, skills.id IN (
        SELECT skill_prereqs.prereq_id
        FROM skill_prereqs
        WHERE skill_prereqs.skill_id = #{skill_id}
      ) AS alreadyPrereq
      FROM skills
    }

    # Lookup table for view to check if skill is already a prerequirement
    @alreadyPrereq = { }
    queryresults.each do |row|
      @alreadyPrereq[row["id"]] = row["alreadyprereq"] == 't' ? true : false
    end

    if @courses.empty?
      respond_to do |format|
        format.text { render :text => "nothing" }
      end
    else
      respond_to do |format|
        format.html { render :partial => "search_results" }
      end
    end
  end

end
