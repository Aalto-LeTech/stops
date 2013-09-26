class Plans::CoursesController < PlansController

  #before_filter :login_required
  before_filter :load_plan


  # GET /studyplan/courses
  # GET /studyplan/courses.xml
  def index
    authorize! :read, @study_plan
    
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
    @competence = Competence.find(params[:competence_id]) if params[:competence_id]

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
    
    log "add_course #{abstract_course.id}"
    
    status = @study_plan.add_course(abstract_course, {
      competence_id: competence_id,
      scoped_course_id: scoped_course_id,
      manually_added: true
    })

    if status == :already_added
      message = {:error => 'Course was already in the study plan'}
    else
      message = {:success => t('plans.courses.course_added_to_plan')}
    end
    
    respond_to do |format|
      format.html {
        if @competence
          redirect_to studyplan_competence_path(:id => @competence.id), :flash => message
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
    
    status = @study_plan.remove_scoped_course(params[:id].to_i)

    if @competence
      redirect_to studyplan_competence_path(:id => @competence.id), :flash => { :success => t('plans.courses.course_removed_from_plan') }
    else
      redirect_to studyplan_competences_path, :flash => { :success => t('plans.courses.course_removed_from_plan') }
    end
  end

end
