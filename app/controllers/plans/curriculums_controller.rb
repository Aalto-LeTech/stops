class Plans::CurriculumsController < PlansController

  before_filter :authenticate_user
  before_filter :load_plan, :only => :show

  # Make sure 'redirect_to' value is not saved here, because edit page uses it for redirect!
  skip_before_filter :store_location


  def show
    # Store 'redirect_to' address so that cancel button works on edit page
    store_location
  end


  def edit
    @user = current_user
    @curriculums = Curriculum.order(:start_year)
  end


  def update
    @user = current_user
    curriculum_id = params[:user_study_plan][:curriculum]

    if not @user.study_plan
      first_period = @user.first_study_period || Period.first_study_period
      last_period = Period.find_by_date(first_period.begins_at - 1 + 365 * StudyPlan::INITIAL_STUDY_PLAN_TIME_IN_YEARS)
      
      @user.study_plan = StudyPlan.create(
        user_id:        current_user.id,
        curriculum_id:  curriculum_id,
        first_period_id: first_period.id,
        last_period_id: last_period.id
      )
      @user.save
    else
      @user.study_plan.curriculum_id = curriculum_id
      @user.study_plan.save
    end

    redirect_to studyplan_competences_path
  end

end
