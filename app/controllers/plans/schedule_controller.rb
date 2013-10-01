class Plans::ScheduleController < PlansController

  before_filter :authenticate_user
  before_filter :load_plan

  def show
    authorize! :update, @study_plan
    
    # Log
    @client_session_id = SecureRandom.hex(3)
    log("view_schedule (#{@client_session_id})")
    
    render :action => 'show', :layout => 'affix-fluid'
  end

end
