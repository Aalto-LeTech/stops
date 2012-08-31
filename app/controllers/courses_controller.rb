class CoursesController < ApplicationController
  
  layout 'course'
  
  before_filter :load_curriculum

  add_translated_crumb 'breadcrumbs.users.index', :users_path
  
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

    add_translated_crumb @course.name, course_path(:id => params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end
  
  # GET /courses/1/graph
  def graph
    @course = ScopedCourse.find(params[:id])

    add_translated_crumb @course.name, course_path(:id => params[:id])
    add_translated_crumb 'breadcrumbs.courses.graph', graph_course_path(:id => params[:id])
  end

  # GET /courses/new
  # GET /courses/new.xml
  def new
    add_translated_crumb 'breadcrumbs.courses.new', new_course_path

    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @course }
    end
  end

  # GET /courses/1/edit
  def edit
    @course = Course.find(params[:id])

    add_translated_crumb @course.name, course_path(:id => params[:id])
    add_translated_crumb 'breadcrumbs.courses.edit', edit_course_path(:id => params[:id])
  end

  # POST /courses
  # POST /courses.xml
  def create
    add_translated_crumb 'breadcrumbs.courses.new', new_course_path

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

  # PUT /courses/1
  # PUT /courses/1.xml
  def update
    @course = Course.find(params[:id])

    add_translated_crumb @course.name, course_path(:id => params[:id])
    add_translated_crumb 'breadcrumbs.courses.edit', edit_course_path(:id => params[:id])

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
  
  
  def skill_dependencies
    
  end
  
end
