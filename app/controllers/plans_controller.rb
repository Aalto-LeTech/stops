# Study plan controller
class PlansController < ApplicationController

  before_filter :authenticate_user!

  before_filter :load_plan
  
  
  def load_plan
    @user = current_user
  end
  
  def show
    @periods = Period.all
    @courses = @user.courses #Course.semesters(@user.courses)
    
    #@credits = UserCourse.sum('credits', :include => :abstract_course, :conditions => ['user_id=?', @user.id])
    
  end
  
  def edit
  end

  
end
