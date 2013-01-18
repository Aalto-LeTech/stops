class Curriculums::TempCoursesController < CurriculumsController
  # GET /temp_courses
  # GET /temp_courses.json
  def index
    @temp_courses = TempCourse.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @temp_courses }
    end
  end

  # GET /temp_courses/1
  # GET /temp_courses/1.json
  def show
    @temp_course = TempCourse.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @temp_course }
    end
  end

  # GET /temp_courses/new
  # GET /temp_courses/new.json
  def new
    @temp_course = TempCourse.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @temp_course }
    end
  end

  # GET /temp_courses/1/edit
  def edit
    @temp_course = TempCourse.find(params[:id])
  end

  # POST /temp_courses
  # POST /temp_courses.json
  def create
    @temp_course = TempCourse.new(params[:temp_course])

    respond_to do |format|
      if @temp_course.save
        format.html { redirect_to @temp_course, notice: 'Temp course was successfully created.' }
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
    @temp_course = TempCourse.find(params[:id])

    respond_to do |format|
      if @temp_course.update_attributes(params[:temp_course])
        format.html { redirect_to @temp_course, notice: 'Temp course was successfully updated.' }
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
    @temp_course = TempCourse.find(params[:id])
    @temp_course.destroy

    respond_to do |format|
      format.html { redirect_to temp_courses_url }
      format.json { head :no_content }
    end
  end
end
