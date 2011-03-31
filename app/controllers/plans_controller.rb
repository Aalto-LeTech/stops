# Study plan controller
class PlansController < ApplicationController

  before_filter :authenticate_user

  before_filter :load_plan
  
  layout 'plan'
  
  def load_plan
    if params[:plan_id]
      @user = User.find_by_studentnumber(params[:plan_id])
    else
      @user = current_user
    end
  end
  
  def load_curriculum
    #@curriculum = Curriculum.find(params[:curriculum_id])
    
    # If curriculum is not chosen, redirect
    unless @user.curriculum
      redirect_to edit_studyplan_curriculum_path
      return false
    end
    
    @curriculum = @user.curriculum
  end
  
  # Overview
  def show
    
  end


  
end
