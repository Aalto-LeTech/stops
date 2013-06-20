# Study plan controller
class Plans::ScheduleController < PlansController
  before_filter :authenticate_user
  before_filter :load_plan

  layout 'wide'

  def show
    @periods        = @user.relevant_periods  # FIXME: move relevant_periods to StudyPlan
    @current_period = Period.current

    @study_plan_courses = @study_plan.study_plan_courses

    #@credits = UserCourse.sum('credits', :include => :abstract_course, :conditions => ['user_id=?', @user.id])
  end

  def edit
  end

  def update
    # TODO: authentication

    if params[:periods]
      params[:periods].each do |user_course_id, period_id|
        user_course = StudyPlanCourse.where(:id => user_course_id).first
        next unless user_course

        user_course.period_id = period_id
        user_course.save
      end
    end

#     respond_to do |format|
#       format.js { render :head => :ok }
#     end
    render :text => 'ok'
  end

end
