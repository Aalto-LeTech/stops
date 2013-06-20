class Plans::CoursesController < PlansController
  
  #before_filter :login_required
  before_filter :load_plan
  
  
  # GET /courses
  # GET /courses.xml
  def index
    @competences = @study_plan.competences
    @user_courses = @user.user_courses
#    @user_courses = @user.study_plan_courses.joins(<<-SQL
#        INNER JOIN competence_nodes ON competence_nodes.id = study_plan_courses.scoped_course_id 
#        LEFT OUTER JOIN course_instances ON course_instances.id = study_plan_courses.course_instance_id 
#        LEFT OUTER JOIN periods ON periods.id = course_instances.period_id
#      SQL
#    ).order("begins_at, course_code")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_courses }
    end
  end

  # GET /courses/1
  # GET /courses/1.xml
  def show
    @course = ScopedCourse.find(params[:id])
    
    if params[:competence_id]
      @competence = Competence.find(params[:competence_id])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end
  
  # GET /courses/1/graph
  def graph
    @course = Course.find(params[:id])
  end

  # GET /courses/new
  # GET /courses/new.xml
  def new
    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @course }
    end
  end

  # GET /courses/1/edit
  def edit
    @course = Course.find(params[:id])
  end

  # Add course to study plan
  # POST /courses
  # POST /courses.xml
  def create
    course = ScopedCourse.find(params[:course_id])

    # FIXME: user StudyPlan instead of User
    # Dont't do anything if user has already selected this profile
    if @user.courses.exists?(course)
      redirect_to studyplan_profiles_path, :flash => {:error => 'Course was already in the study plan'}
      return
    end
    
    # Add course to study plan
    UserCourse.create(:user_id => @user.id, :scoped_course_id => course.id, :manually_added => true)
    
    redirect_to studyplan_profiles_path, :flash => {:success => 'Course added to study plan'}
  end

  # PUT /courses/1
  # PUT /courses/1.xml
  def update
    @course = Course.find(params[:id])

    respond_to do |format|
      if @course.update_attributes(params[:course])
        format.html { redirect_to(@course, :notice => 'Course was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.xml
  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html { redirect_to(courses_url) }
      format.xml  { head :ok }
    end
  end
end
