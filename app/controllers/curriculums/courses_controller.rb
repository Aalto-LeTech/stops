class Curriculums::CoursesController < CurriculumsController
  
  before_filter :load_curriculum
 
  # GET /courses
  # GET /courses.xml
  def index
    @courses = @curriculum.courses

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
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
  
end
