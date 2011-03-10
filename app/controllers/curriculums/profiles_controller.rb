class Curriculums::ProfilesController < CurriculumsController
  
  before_filter :load_curriculum
  
  
  # GET /curriculums/1/profiles
  # GET /curriculums/1//profiles.xml
  def index
    @profiles = @curriculum.profiles

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
    end
  end

  # GET /curriculums/1/profiles/1
  # GET /curriculums/1/profiles/1.xml
  def show
    @profile = Profile.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end

  def new
    
  end
  

end
