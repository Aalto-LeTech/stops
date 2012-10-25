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

  def edit
    @scoped_course = ScopedCourse.find(params[:id])
    
    authorize! :update, @curriculum
    
    #@profile.profile_descriptions << ProfileDescription.new(:locale => I18n.locale) if @profile.profile_descriptions.empty?
  end

  def new
    authorize! :update, @curriculum
    
    @abstract_course = AbstractCourse.new
    @abstract_course.course_descriptions_with_locale << CourseDescription.new(:locale => I18n.locale)
    @scoped_course = ScopedCourse.new
  end
  
  def create
    authorize! :update, @curriculum
    
    @abstract_course = AbstractCourse.new
    @scoped_course = ScopedCourse.new
    @scoped_course.abstract_course = @abstract_course
    @scoped_course.curriculum = @curriculum
    @scoped_course.assign_attributes(params[:scoped_course])

    if @scoped_course.save
      redirect_to curriculum_path(@curriculum)
    else
      render :action => "new"
    end
  end
  
  def update
    @profile = Profile.find(params[:id])
    authorize! :update, @curriculum

    if @profile.update_attributes(params[:profile])
      redirect_to curriculum_profile_path(:curriculum_id => @curriculum, :id => @profile)
    else
      render :action => "edit"
    end
  end

  
end
