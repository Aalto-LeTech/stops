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
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end

  # Add course to study plan
  # POST /plans/:id/courses
  def create
    authorize! :update, @study_plan
    
    abstract_course = AbstractCourse.find(params[:abstract_course_id])
    competence_id = Integer(params[:competence_id]) rescue nil
    scoped_course_id = Integer(params[:scoped_course_id]) rescue nil
    
    status = @study_plan.add_course(abstract_course, {
      competence_node_id: competence_id,
      scoped_course_id: scoped_course_id,
      manually_added: true
    })
    
    if status == :already_added
      message = {:error => 'Course was already in the study plan'}
    else
      message = {:success => t('plans.courses.course_added_to_plan')}
    end
    
    log "add_course #{abstract_course.id}, competence #{competence_id}, scoped_course #{scoped_course_id}"
    
    respond_to do |format|
      format.html {
        if competence_id
          redirect_to studyplan_competence_path(:id => competence_id), :flash => message
        else
          redirect_to studyplan_competences_path, :flash => message
        end
      }
      # TODO: add error message
      format.json { render json: { status: 'ok' }.to_json( root: false ) }
    end
    
  end

  # Remove course from study plan
  # DESTROY /plans/:id/courses
  def destroy
    authorize! :update, @study_plan
    @competence = nil
    @competence = Competence.find(params[:competence_id]) if params[:competence_id]
    
    if params[:abstract_course_id]
      status = @study_plan.remove_abstract_courses(params[:abstract_course_id])
      log "remove_course #{params[:abstract_course_id]}"
    else
      status = @study_plan.remove_scoped_course(params[:id])
      log "remove_scoped_course #{params[:id]}"
    end
    
    if @competence
      redirect_to studyplan_competence_path(:id => @competence.id), :flash => { :success => t('plans.courses.course_removed_from_plan') }
    else
      redirect_to studyplan_competences_path, :flash => { :success => t('plans.courses.course_removed_from_plan') }
    end
  end

end
