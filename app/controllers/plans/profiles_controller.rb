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
    @selected_profiles = @user.competences

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @courses }
    end
  end

  # GET /plans/1//profiles/1
  # GET /plans/1//profiles/1.xml
  def show
    @profile = Profile.find(params[:id])
    
    @competences = @profile.competences
    @included_courses = @user.courses
    
    @passed_courses = Hash.new
    @user.passed_courses.each do |course|
      @passed_courses[course.id] = course
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @course }
    end
  end
  
end
