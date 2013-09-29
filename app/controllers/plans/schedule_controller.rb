class Plans::ScheduleController < PlansController

  before_filter :authenticate_user
  before_filter :load_plan

  def show
    authorize! :update, @study_plan
    render :action => 'show', :layout => 'affix-fluid'
  end

end
