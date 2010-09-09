# Study plan controller
class PlansController < ApplicationController

  before_filter :login_required
  
  before_filter :load_plan
  
  
  def load_plan
    @user = current_user
  end
  
  def show
    @semesters = Course.semesters(@user.courses)
    
    @credits = UserCourse.sum('credits', :include => :course, :conditions => ['user_id=?', @user.id])
    
  end
  
  def edit
  end

  
end
