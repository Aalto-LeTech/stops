class Plans::CoursesController < PlansController

  #before_filter :login_required
  before_filter :load_plan


  # GET /studyplan/courses
  # GET /studyplan/courses.xml
  def index
    authorize! :read, @study_plan
    
    respond_to do |format|
      format.html { render :action => 'index', :layout => 'browser' }
      format.xml  { render :xml => nil }
    end
  end

  # GET /studyplan/courses/1
  # GET /studyplan/courses/1.xml
  def show
    authorize! :read, @study_plan
    @course = ScopedCourse.find(params[:id])

    if params[:competence_id]
      @competence = Competence.find(params[:competence_id])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end

#  # GET /courses/1/graph
#  def graph
#    @course = Course.find(params[:id])
#  end

#  # GET /courses/new
#  # GET /courses/new.xml
#  def new
#    @course = Course.new

#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @course }
#    end
#  end

#  # GET /courses/1/edit
#  def edit
#    @course = Course.find(params[:id])
#  end

  # Add course to study plan
  # POST /plans/:id/courses
  def create
    authorize! :update, @study_plan
    status = @study_plan.add_course(params[:course_id].to_i, true)

    if status == :already_added
      redirect_to studyplan_competences_path, :flash => {:error => 'Course was already in the study plan'}
    else
      redirect_to studyplan_competences_path, :flash => {:success => 'Course added to study plan'}
    end
  end

end
