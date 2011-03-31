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
  
  def edit
    @profile = Profile.find(params[:id])
    
    authorize! :edit, @profile
    
    @profile.profile_descriptions << ProfileDescription.new(:locale => I18n.locale) if @profile.profile_descriptions.empty?
  end

  def new
    @profile = Profile.new
    
    @profile.profile_descriptions << ProfileDescription.new(:locale => I18n.locale)
  end
  
  def create
    @profile = Profile.new(params[:profile])
    @profile.curriculum = @curriculum
    authorize! :create, @profile

    if @profile.save
      @profile.create_default_competences
      
      redirect_to curriculum_path(@curriculum), :success => t(:profile_created_flash)
    else
      render :action => "new"
    end
  end
  
  def update
    @profile = Profile.find(params[:id])
    authorize! :edit, @profile

    if @profile.update_attributes(params[:profile])
      redirect_to curriculum_profile_path(:curriculum_id => @curriculum, :id => @profile)
    else
      render :action => "edit"
    end
  end

end
