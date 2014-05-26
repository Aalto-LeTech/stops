class Plans::CoursesController < PlansController

  #before_filter :login_required
  before_filter :load_plan

  # GET /studyplan/courses
  # GET /studyplan/courses.xml
  def index
    authorize! :read, @study_plan
    
    # Log
    @client_session_id = SecureRandom.hex(3)
    log("view_courses (#{@client_session_id})")
    
    respond_to do |format|
      format.html { render :action => 'index', :layout => 'affix-fixed' }
      format.xml  { render :xml => nil }
    end
  end

  # GET /studyplan/courses/1
  # GET /studyplan/courses/1.xml
  def show
    # Obsolete?
    authorize! :read, @study_plan
    @course = ScopedCourse.find(params[:id])
    @competence = nil
    @competence = Competence.find(params[:competence_id]) if params[:competence_id]

    # Log
    @client_session_id = SecureRandom.hex(3)
    if @competence
      log("view_competence_course #{@competence.id} #{@course.id} (#{@client_session_id})")
    else
      log("view_course #{@course.id} (#{@client_session_id})")
    end
    
    render :action => 'show', :layout => 'leftnav'
  end

  # Add course to study plan
  # POST /plans/:id/courses
  def create
    authorize! :update, @study_plan
    
    abstract_course = AbstractCourse.find(params[:abstract_course_id])
    competence_id = Integer(params[:competence_id]) rescue nil
    scoped_course_id = Integer(params[:scoped_course_id]) rescue nil
    
    scoped_course = nil
    
    
    plan_course = @study_plan.add_course(abstract_course, {
      competence_node_id: competence_id,
      scoped_course_id: scoped_course_id,
      manually_added: true
    })
    
    log "add_course #{abstract_course.id}, competence #{competence_id}, scoped_course #{scoped_course_id}"
    
    respond_to do |format|
      format.html {
        if competence_id
          competence = Competence.find(competence_id)
          redirect_to curriculum_competence_path(:curriculum_id => competence.curriculum_id, :id => competence_id), :flash => { :success => t('plans.courses.course_added_to_plan') }
          #studyplan_competence_path(:id => competence_id)
        else
          scoped_course = ScopedCourse.find(scoped_course_id) if scoped_course_id
          redirect_to root_path # FIXME
          # studyplan_competences_path, :flash => { :success => t('plans.courses.course_added_to_plan') }
        end
      }
      # TODO: add error message
      format.json { render json: { status: 'ok', plan_course_id: plan_course.id }.to_json( root: false ) }
    end
    
  end

  # Remove course from study plan. Use abstract_course_id
  # DESTROY /plans/:plan_id/courses/:id
  def destroy
    authorize! :update, @study_plan
    @competence = nil
    @competence = Competence.find(params[:competence_id]) if params[:competence_id]
    
    #if params[:abstract_course_id]
      status = @study_plan.remove_abstract_courses(params[:id])
      log "remove_course #{params[:id]}"
    #else
    #  status = @study_plan.remove_scoped_course(params[:id])
    #  log "remove_scoped_course #{params[:id]}"
    #end
    
    respond_to do |format|
      format.html {
        if @competence
          redirect_to curriculum_competence_path(curriculum_id: @competence.curriculum_id, id: @competence.id), :flash => { :success => t('plans.courses.course_removed_from_plan') }
        else
          redirect_to root_path # FIXME
          #studyplan_competences_path, :flash => { :success => t('plans.courses.course_removed_from_plan') }
        end
      }
      format.json { render json: { status: 'ok' }.to_json( root: false ) }
    end
  end

end
