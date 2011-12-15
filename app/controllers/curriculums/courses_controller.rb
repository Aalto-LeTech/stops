class Curriculums::CoursesController < CurriculumsController

  before_filter :load_curriculum


  #layout 'curriculum', :only => [:index, :show]
  #layout 'fullscreen', :only => [:prereqs]

  respond_to :json, :only => 'index'

  # GET /courses
  # GET /courses.xml
  def index
    #@courses = @curriculum.courses

    @courses = ScopedCourse.where(:curriculum_id => @curriculum.id).joins('INNER JOIN course_descriptions ON scoped_courses.abstract_course_id = course_descriptions.abstract_course_id').where(["course_descriptions.locale = ?", I18n.locale]).includes(:strict_prereqs)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
      format.json { render :json => @courses.select("scoped_courses.id, scoped_courses.code, course_descriptions.name AS translated_name").to_json(:methods => :strict_prereq_ids) }
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


  def prereqs
    @course = ScopedCourse.find(params[:id])

    render :action => 'prereqs', :layout => 'fullscreen'
  end

end
