class Plans::ScheduleController < PlansController

  before_filter :authenticate_user
  before_filter :load_plan

  layout 'browser'

  def show
  end

  def edit
  end

end
