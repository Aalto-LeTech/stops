class CurriculumsController < ApplicationController
  before_filter :authorize_admin, :except => [:index, :show]
  
  # GET /curriculums
  # GET /curriculums.xml
  def index
    @curriculums = Curriculum.all(:order => 'start_year DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @curriculums }
    end
  end

  # GET /curriculums/1
  # GET /curriculums/1.xml
  def show
    @curriculum = Curriculum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @curriculum }
    end
  end

  # GET /curriculums/new
  # GET /curriculums/new.xml
  def new
    @curriculum = Curriculum.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @curriculum }
    end
  end

  # GET /curriculums/1/edit
  def edit
    @curriculum = Curriculum.find(params[:id])
  end

  # POST /curriculums
  # POST /curriculums.xml
  def create
    @curriculum = Curriculum.new(params[:curriculum])

    respond_to do |format|
      if @curriculum.save
        format.html { redirect_to(curriculum_url(:id => @curriculum), :notice => 'Curriculum was successfully created.') }
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

    if params[:prereqs_csv]
      matrix = PrereqMatrix.new(params[:prereqs_csv], @curriculum, I18n.locale)
      matrix.process
      flash[:success] = "#{params[:prereqs_csv].original_filename} uploaded"
    end
    
    if params[:profiles_csv]
      matrix = ProfileMatrix.new(params[:profiles_csv], @curriculum, I18n.locale)
      matrix.process
      flash[:success] = "#{params[:prereqs_csv].original_filename} uploaded"
    end
    
    render :action => "edit"
    
#     respond_to do |format|
#       if @curriculum.update_attributes(params[:curriculum])
#         format.html { redirect_to(@curriculum, :notice => 'Curriculum was successfully updated.') }
#         format.xml  { head :ok }
#       else
#         format.html { render :action => "edit" }
#         format.xml  { render :xml => @curriculum.errors, :status => :unprocessable_entity }
#       end
#     end
  end

  # DELETE /curriculums/1
  # DELETE /curriculums/1.xml
  def destroy
    @curriculum = Curriculum.find(params[:id])
    @curriculum.destroy

    respond_to do |format|
      format.html { redirect_to(curriculums_url) }
      format.xml  { head :ok }
    end
  end
end
