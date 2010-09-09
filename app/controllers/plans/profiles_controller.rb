class Plans::ProfilesController < PlansController
  
  before_filter :login_required
  before_filter :load_plan
  
  
  def load_plan
    @user = current_user
  end
  
  # GET /plans/1/profiles
  # GET /plans/1//profiles.xml
  def index
    @profiles = @user.profiles

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

  # Adds a profile to the study plan
  # POST /plans/1/profiles
  # POST /plans/1/profiles.xml
  def create
    # Dont't do anything if user has already selected this profile
    #return if @user.profiles.exists?(params[:profile_id])
    
    profile = Profile.find(params[:profile_id])
    # TODO: if not found
    
    # Add profile to study plan
    @user.add_profile(profile)
    
    # Add courses to study plan
    #@user.courses << profile.courses_recursive
    
    redirect_to plan_path
  end

  # Removes a profile from the study plan
  # DELETE /plans/1/profiles/1
  # DELETE /plans/1/profiles/1.xml
  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html { redirect_to(courses_url) }
      format.xml  { head :ok }
    end
  end
end
