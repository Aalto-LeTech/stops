# Study plan controller
class PlansController < ApplicationController

  before_filter :authenticate_user

  before_filter :load_plan
  
  layout 'plan'
  
  def load_plan
    @user = current_user
    
    if params[:studyplan_id]
      @study_plan = StudyPlan.find(params[:studyplan_id])
    else
      @study_plan = @user.study_plan
      unless @study_plan
        redirect_to edit_studyplan_curriculum_path
        return false
      end
    end
    
    @curriculum = @user.study_plan.curriculum
  end

  
  # Overview
  def show
    
  end


  
end
