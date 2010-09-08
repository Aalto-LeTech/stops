# Study plan controller
class PlansController < ApplicationController

  before_filter :login_required
  
  before_filter :load_plan
  
  
  def load_plan
    @user = current_user
  end
  
  def show
    
    
  end
  
  def edit
  end

  
end
