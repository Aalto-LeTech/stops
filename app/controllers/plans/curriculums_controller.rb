class Plans::CurriculumsController < PlansController
  
  before_filter :authenticate_user
  before_filter :load_plan
  before_filter :load_plan
  before_filter :load_curriculum, :only => :show

  # Make sure 'redirect_to' value is not saved here, because edit page uses it for redirect!
  skip_before_filter :store_location
  
  def show
    # Store 'redirect_to' address so that cancel button works on edit page
    store_location
  end
  

  def edit
    @curriculums = Curriculum.order(:start_year)
  end

  def cancel_edit
    redirect_back_or_default studyplan_curriculum_path
  end

  
  def update

    curriculum_id = params[:user_study_plan][:curriculum]

    if not @user.study_plan
      @user.study_plan = StudyPlan.create :user_id => current_user.id, :curriculum_id => curriculum_id
      @user.save
    else
      @user.study_plan.curriculum_id = curriculum_id
      @user.study_plan.save
    end

    redirect_back_or_default studyplan_curriculum_path
#     respond_to do |format|
#       if @course.update_attributes(params[:course])
#         format.html { redirect_to(@course, :notice => 'Course was successfully updated.') }
#         format.xml  { head :ok }
#       else
#         format.html { render :action => "edit" }
#         format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
#       end
#     end
  end

end
