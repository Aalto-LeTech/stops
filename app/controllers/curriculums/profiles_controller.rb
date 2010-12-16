class Curriculums::ProfilesController < CurriculumsController
  
  before_filter :load_curriculum
  
  
  # GET /plans/1/profiles
  # GET /plans/1//profiles.xml
  def index
    @profiles = @curriculum.profiles

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
    end
  end

  # GET /plans/1/profiles/1
  # GET /plans/1/profiles/1.xml
  def show
    @profile = Profile.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end
  

end
