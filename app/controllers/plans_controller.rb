# Study plan controller
class PlansController < ApplicationController

  before_filter :login_required
  
  def show
    @user = current_user
  end
  
  def edit
  end

  
end
