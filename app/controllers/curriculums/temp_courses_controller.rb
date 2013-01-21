class Curriculums::TempCoursesController < CurriculumsController
  before_filter :load_curriculum
  
  layout 'wide'
  
  # GET /temp_courses
  # GET /temp_courses.json
  def index
    authorize! :read, @curriculum
    @temp_courses = TempCourse.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @temp_courses }
    end
  end

  # GET /temp_courses/1
  # GET /temp_courses/1.json
  def show
    authorize! :read, @curriculum
    @temp_course = TempCourse.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @temp_course }
    end
  end

  # GET /temp_courses/new
  # GET /temp_courses/new.json
  def new
    authorize! :create_course, @curriculum
    @temp_course = TempCourse.new
    
    @temp_course.contact = "#{current_user.name} <#{current_user.email}>"
    
    render :action => 'form'
  end

  # GET /temp_courses/1/edit
  def edit
    authorize! :create_course, @curriculum
    @temp_course = TempCourse.find(params[:id])
    
    render :action => 'form'
  end

  # POST /temp_courses
  # POST /temp_courses.json
  def create
    authorize! :create_course, @curriculum
    
    @temp_course = TempCourse.new(params[:temp_course])
    @temp_course.curriculum = @curriculum
    @temp_course.update_comments(params[:comments])

    respond_to do |format|
      if @temp_course.save
        format.html { redirect_to @curriculum, notice: t('curriculums.temp_courses.created', :name => @temp_course.name_fi)}
        format.json { render json: @temp_course, status: :created, location: @temp_course }
      else
        format.html { render action: "new" }
        format.json { render json: @temp_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /temp_courses/1
  # PUT /temp_courses/1.json
  def update
    authorize! :create_course, @curriculum
    
    @temp_course = TempCourse.find(params[:id])
    
    @temp_course.update_comments(params[:comments])

    respond_to do |format|
      if @temp_course.update_attributes(params[:temp_course])
        format.html { redirect_to @curriculum, notice: t('curriculums.temp_courses.updated', :name => @temp_course.name_fi) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @temp_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /temp_courses/1
  # DELETE /temp_courses/1.json
  def destroy
    authorize! :create_course, @curriculum
    
    @temp_course = TempCourse.find(params[:id])
    @temp_course.destroy

    respond_to do |format|
      format.html { redirect_to temp_courses_url }
      format.json { head :no_content }
    end
  end
end
