class Plans::CurriculumsController < PlansController

  before_filter :authenticate_user
  before_filter :load_plan, :only => :show

  # Make sure 'redirect_to' value is not saved here, because edit page uses it for redirect!
  skip_before_filter :store_location

  layout 'fixed'
  
  def show
    authorize! :read, @user
    
    # Store 'redirect_to' address so that cancel button works on edit page
    store_location
  end

  def edit
    @user = current_user
    authorize! :update, @user
    @curriculums = Curriculum.order(:start_year)
  end

  def update
    @user = current_user
    authorize! :update, @user
    
    if params[:user_study_plan]
      if @user.study_plan
        @user.study_plan.save
      else
        @user.create_study_plan()
      end
    end
    
    redirect_to studyplan_competences_path
  end

end
