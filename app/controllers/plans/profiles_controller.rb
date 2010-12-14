class Plans::ProfilesController < PlansController
  
  #before_filter :login_required
  before_filter :load_plan
  before_filter :load_curriculum
  
  
  def load_plan
    @user = current_user
  end
  
  # GET /plans/1/profiles
  # GET /plans/1//profiles.xml
  def index
    @profiles = @curriculum.profiles
    @selected_profiles = @user.profiles

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
    end
  end

  # GET /plans/1//profiles/1
  # GET /plans/1//profiles/1.xml
  def show
    @profile = Profile.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end
  
  # Prepare to add profile to studyplan
  def new
    @profile = Profile.find(params[:id])
    
    user_courses = @user.courses
    @new_courses = @profile.courses_recursive - user_courses # difference
    @existing_courses = user_courses & @profile.strict_prereqs # intersection
    
    # If profile is aleady in the plan, don't do anything
    if @user.profiles.exists?(@profile.id)
      redirect_to studyplan_profiles_path, :flash => {:error => t(:profile_already_selected, :name => @profile.name(I18n.locale))}
    end
  end

  # Adds a profile to the study plan
  # POST /plans/1/profiles
  # POST /plans/1/profiles.xml
  def create
    # Dont't do anything if user has already selected this profile
    if @user.profiles.exists?(params[:profile_id])
      redirect_to studyplan_profiles_path, :flash => {:error => t(:profile_already_selected, :name => @profile.name(I18n.locale))}
    end
    
    profile = Profile.find(params[:profile_id])
    # TODO: if not found
    
    # Add profile to study plan
    @user.add_profile(profile)
    
    # Add courses to study plan
    #@user.courses << profile.courses_recursive
    
    redirect_to studyplan_profiles_path
  end

  def delete
    @profile = Profile.find(params[:id])
    @courses = @user.deletable_courses(@profile)
  end
  
  # Removes a profile from the study plan
  # DELETE /plans/1/profiles/1
  # DELETE /plans/1/profiles/1.xml
  def destroy
    profile = Profile.find(params[:id])
    @user.remove_profile(profile)

    respond_to do |format|
      format.html { redirect_to(studyplan_profiles_path) }
      format.xml  { head :ok }
    end
  end
end
