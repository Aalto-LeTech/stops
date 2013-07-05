class Plans::PeriodsController < PlansController

  before_filter :load_plan


  # GET /periods
  # GET /periods.xml
  def index
    @user = current_user
    @period_data = @user.study_plan.ordered_array_of_periods_with_scheduled_courses

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @period_data }
    end
  end

  # GET /periods/1
  # GET /periods/1.xml
  def show
    @user = current_user
    period_data = @user.study_plan.ordered_array_of_periods_with_scheduled_courses

    period_id = params[:id].to_i
    period_index = nil
    period_data.each_with_index do |period_data, index|
      if period_data[:period].id == period_id
        period_index = index
        break
      end
    end

    if period_index != nil
      @pd_prev = period_index > 0 ? period_data[ period_index - 1 ] : nil
      @pd_this = period_data[ period_index ]
      @pd_next = period_data.size > period_index + 1 ? period_data[ period_index + 1 ] : nil
    else
      @period = Period.find( params[:id] )
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => [ @pd_this, @pd_prev, @pd_next, @period ] }
    end
  end

end
