class Curriculums::SkillsController < CurriculumsController

  before_filter :load_curriculum

  respond_to :json, :only => [:index, :edit, :search_skills_and_courses]

  def index
    # TODO: only load skills that belong to this curriculum
    @skills = Skill.joins(:competence_node)
                .includes(:strict_prereqs, :supporting_prereqs, :localized_description)
                .order(:competence_node_id, :position)
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

  # GET curriculum/:id/skills/:id
#   def show
#     @skill = Skill.find(params[:id])
# 
#     @competence = Competence.find(params[:competence_id]) if params[:competence_id]
#     @profile = @competence.profile
# 
#     @courses = @skill.contributing_skills
# 
#     respond_to do |format|
#       format.html # show.html.erb
#       format.xml  { render :xml => @skill }
#     end
#   end

  def new
    authorize! :update, @curriculum

    @skill = Skill.new
    @skill.competence_node = Competence.find(params[:competence_id])

    # Create empty descriptions for each required locale
    REQUIRED_LOCALES.each do |locale|
      @skill.skill_descriptions << SkillDescription.new(:locale => locale)
    end

    respond_to do |format|
      format.js
    end
  end

  # POST /curriculum/:id/skills
  def create
    authorize! :update, @curriculum

    @skill = Skill.new(params[:skill])
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

    @skill = Skill.find(params[:id])
    @skill.update_attributes(params[:skill])

    respond_to do |format|
      format.js {
        render :json => @skill.to_json(:include => [:skill_descriptions], :root => true)
      }
    end
  end

  def update_position
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

    @skill = Skill.find(params[:id])
    @skill.destroy

    respond_to do |format|
      format.js {
        render :nothing => true
      }
    end
  end

  # POST /curriculums/:curriculum_id/skills/:id/add_prereq
  def add_prereq
    authorize! :update, @curriculum

    requirement_type = params[:requirement] || STRICT_PREREQ

    # Reset
    SkillPrereq.where(:skill_id => params[:id], :prereq_id => params[:prereq_id]).delete_all

    # Add new
    SkillPrereq.create :skill_id     => Integer(params[:id]),
                       :prereq_id    => Integer(params[:prereq_id]),
                       :requirement  => requirement_type

    # Update course prereqs
    target_skill = Skill.find(params[:id])
    if target_skill.competence_node.is_a?(ScopedCourse)
      target_skill.competence_node.update_prereqs_cache
    end

    render :nothing => true
  end

  # POST /curriculums/:curriculum_id/skills/:id/remove_prereq
  # params: {'prereq_id': prereq_skill_id}
  def remove_prereq
    authorize! :update, @curriculum

    @prereq = SkillPrereq.where "skill_id = ? AND prereq_id = ?",
                params[:id], params[:prereq_id]

    @prereq.all.each do |prereq|
      prereq.destroy
    end
    
    # Update course prereqs
    target_skill = Skill.find(params[:id])
    if target_skill.competence_node.is_a?(ScopedCourse)
      target_skill.competence_node.update_prereqs_cache
    end

    render :nothing => true
  end

  # GET /:id/edit
  def edit
    respond_to do |format|
      format.html do
        #render "edit_skill_prereqs.js.erb"

        # Validate query string key
        render(:nothing => true, :status => 500) unless /^\d+$/ =~ params[:id]

        # Find all courses within curriculum that have at least one skill as a
        # a prerequirement to the skill being edited
        @prereq_courses = ScopedCourse.find(
                            :all,
                            :conditions => [
                              'curriculum_id = ? AND "skill_prereqs"."skill_id" = ?',
                              params[:curriculum_id], params[:id]
                            ],
                            :include => [
                              :localized_course_description,
                              { :skills => [:prereq_to, :localized_description] }
                            ]
                          )

        @skill = Skill.includes(:localized_description).find(params[:id].to_i)

        # Render an eco template for each course (This is done to use the same template
        # for Javascript view updates)
        eco_template_path = File.join(Rails.root,
          "app/assets/javascripts/templates/_current_course_with_prereq_skills.jst.eco")
        eco_template = File.read(eco_template_path)

        @courses_rendered = []
        @prereq_courses.each do |course|
          skills = []
          course.skills.each do |skill|
            skill_locals = {
              :description  => skill.localized_name,
              :id           => skill.id,
              :is_prereq    => skill.is_prereq_to?(@skill.id)
            }
            skills << skill_locals
          end
          locals = {
            :render_whole_course  => true,
            :course_id            => course.id,
            :course_code          => course.course_code,
            :course_name          => course.localized_name,
            :course_skills        => skills,
            :button_text          => t('add_prereq_button_remove', :scope => 'curriculums.skills.edit')
          }

          @courses_rendered << Eco.render(eco_template, locals)
        end

        @skill_id = params[:id]
      end
    end
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
