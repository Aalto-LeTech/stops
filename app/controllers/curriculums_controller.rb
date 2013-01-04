class CurriculumsController < ApplicationController

  respond_to :html
  respond_to :json, :only => 'prereqs'

  layout 'curriculum'

  #caches_page :prereqs

  def load_curriculum
    @curriculum = Curriculum.find(params[:curriculum_id])
  end

  # GET /curriculums
  # GET /curriculums.xml
  def index
    @curriculums = Curriculum.all(:order => 'start_year DESC')
    authorize! :read, Curriculum

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @curriculums }
    end
  end

  # GET /curriculums/1
  # GET /curriculums/1.xml
  def show
    load_curriculum_for_show_and_edit

    authorize! :read, @curriculum

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @curriculum }
    end
  end

  # GET /curriculums/new
  # GET /curriculums/new.xml
  def new
    @curriculum = Curriculum.new
    authorize! :create, @curriculum

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @curriculum }
    end
  end

  # GET /curriculums/1/edit
  def edit
    load_curriculum_for_show_and_edit
    authorize! :update, @curriculum
  end

  # GET /curriculums/1/edit/import_csv
  def import_csv
    @curriculum = Curriculum.find(params[:id])
    authorize! :update, @curriculum
  end

  # POST /curriculums
  # POST /curriculums.xml
  def create
    @curriculum = Curriculum.new(params[:curriculum])
    authorize! :create, @curriculum

    @curriculum.admins << @current_user

    respond_to do |format|
      if @curriculum.save
        format.html { redirect_to(edit_curriculum_url(:id => @curriculum), :notice => 'Curriculum was successfully created.') }
        format.xml  { render :xml => @curriculum, :status => :created, :location => @curriculum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @curriculum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /curriculums/1
  # PUT /curriculums/1.xml
  def update
    @curriculum = Curriculum.find(params[:id])
    authorize! :update, @curriculum

    if params[:prereqs_csv]
      matrix = PrereqMatrix.new(params[:prereqs_csv], @curriculum, I18n.locale)
      matrix.process
      flash[:success] = "#{params[:prereqs_csv].original_filename} uploaded"
      redirect_to edit_import_csv_curriculum_path(@curriculum)
    elsif params[:profiles_csv]
      matrix = ProfileMatrix.new(params[:profiles_csv], @curriculum, I18n.locale)
      matrix.process
      flash[:success] = "#{params[:profiles_csv].original_filename} uploaded"
      redirect_to edit_import_csv_curriculum_path(@curriculum)
    else
      respond_to do |format|
        if @curriculum.update_attributes(params[:curriculum])
          format.html { redirect_to(@curriculum, :notice => 'Curriculum was successfully updated.') }
          format.js { head :ok }
        else
          format.html { render :action => "edit", :notice => 'Saving unsuccessful, no data saved!'}
          format.js { head :internal_server_error }
        end
      end
    end
  end

  # DELETE /curriculums/1
  # DELETE /curriculums/1.xml
  def destroy
    @curriculum = Curriculum.find(params[:id])
    authorize! :destroy, @curriculum

    @curriculum.destroy

    respond_to do |format|
      format.html { redirect_to(curriculums_url) }
      format.xml  { head :ok }
    end
  end

  def cycles
    @curriculum = Curriculum.find(params[:id])

    @cycles = @curriculum.detect_cycles
  end


  # Get all strict prereqs of all courses
  def prereqs
    @curriculum = Curriculum.find(params[:id])

    prereqs = CoursePrereq.where(:requirement => STRICT_PREREQ).joins('INNER JOIN scoped_courses AS course ON course.id = course_prereqs.scoped_course_id INNER JOIN scoped_courses AS prereq ON prereq.id = course_prereqs.scoped_prereq_id').where("course.curriculum_id = ?", @curriculum).select('course.code AS course_code, prereq.code AS prereq_code, course.id AS course_id, prereq.id AS prereq_id')

    respond_to do |format|
      format.html { render :text => prereqs.to_json }
      format.xml { render :xml => prereqs }
      format.json { render :json => prereqs }
    end
  end

  def graph
    @curriculum = Curriculum.find(params[:id])

    prereqs = CoursePrereq.joins(:course).where("scoped_courses.curriculum_id = ?", @curriculum).where(:requirement => STRICT_PREREQ)
    render :action => 'graphviz', :locals => {:prereqs => prereqs}, :layout => false, :content_type => 'text/x-graphviz'
  end

  def outcomes
    @curriculum = Curriculum.find(params[:id])
  end

  private

  # Loads curriculum object with necessary associations eagerly loaded
  def load_curriculum_for_show_and_edit
    @curriculum = Curriculum.includes(
      :courses,
      :profiles,
      :courses => [:abstract_course, :periods, :course_description_with_locale, :strict_prereqs],
    ).find(params[:id])
  end

end
