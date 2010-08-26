class Profiles::CoursesController < ProfilesController
  
  layout 'profile'
  
  before_filter :load_curriculum
  before_filter :load_profile
  
  
  # GET /profiles/1/courses
  # GET /profiles/1/courses.xml
  def index
    @courses = Course.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
    end
  end

  # GET /profiles/1/courses/1
  # GET /profiles/1/courses/1.xml
  def show
    @course = Course.find(params[:id])

#     respond_to do |format|
#       format.html # show.html.erb
#       format.xml  { render :xml => @course }
#     end
    
    render :action => 'show'
  end

  # GET /profiles/1/courses/new
  # GET /profiles/1/courses/new.xml
  def new
    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @course }
    end
  end

  # POST /profiles/1/courses
  # POST /profiles/1/courses.xml
  def create
    @course = Course.new(params[:course])

    respond_to do |format|
      if @course.save
        format.html { redirect_to(@course, :notice => 'Course was successfully created.') }
        format.xml  { render :xml => @course, :status => :created, :location => @course }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/courses/1
  # DELETE /profiles/1/courses/1.xml
  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html { redirect_to(courses_url) }
      format.xml  { head :ok }
    end
  end
end
