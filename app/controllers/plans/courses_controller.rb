class Plans::CoursesController < PlansController
  
  #before_filter :login_required
  before_filter :load_plan
  before_filter :load_curriculum
  
  
  # GET /courses
  # GET /courses.xml
  def index
    @user_courses = @user.user_courses.joins("INNER JOIN scoped_courses ON scoped_courses.id = user_courses.scoped_course_id LEFT OUTER JOIN course_instances ON course_instances.id = user_courses.course_instance_id LEFT OUTER JOIN periods ON periods.id = course_instances.period_id").order("begins_at, code")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @user_courses }
    end
  end

  # GET /courses/1
  # GET /courses/1.xml
  def show
    @course = ScopedCourse.find(params[:id])
    
    @profile = Profile.find(params[:profile_id]) if params[:profile_id]

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

    # Dont't do anything if user has already selected this profile
    if @user.courses.exists?(course)
      redirect_to studyplan_profiles_path, :flash => {:error => 'Course was already in the study plan'}
      return
    end
    
    # Add course to study plan
    @user.courses << course
    
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
