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
      @user.study_plan = StudyPlan.create(
        user_id:        current_user.id,
        curriculum_id:  curriculum_id
      )
      @user.save
    else
      @user.study_plan.curriculum_id = curriculum_id
      @user.study_plan.save
    end

    redirect_back_or_default studyplan_curriculum_path
  end

end
