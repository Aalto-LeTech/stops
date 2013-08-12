class Plans::ScheduleController < PlansController

  before_filter :authenticate_user
  before_filter :load_plan

  def show
    render :action => 'show', :layout => 'browser'
  end

end
