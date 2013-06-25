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


  # /plans/123.json returns the plan as JSON
  #   {
  #     "study_plan": {
  #       "curriculum_id":3,
  #       "study_plan_courses":[
  #         {"period_id":null,"scoped_course_id":71},
  #         {"period_id":null,"scoped_course_id":35},
  #         ...
  #       ]
  #     },
  #     "courses": [
  #       {"course_code":"MS-A0001","id":10,"localized_name":"Matriisilaskenta"},
  #       {"course_code":"MS-A0101","id":11,"localized_name":"Differentiaalilaskenta"},
  #       ...
  #     ],
  #     "periods": [
  #       {"id":25,"number":4,"localized_name":"2009 II syksy"},
  #       {"id":26,"number":0,"localized_name":"2010 III kevat"},
  #       ...
  #     ]
  #   }
  def show
    authorize! :read, @study_plan
    
    periods = @user.relevant_periods.includes(:localized_description).as_json(:only => [:id, :number], :methods => [:localized_name], :root => false)
    scoped_courses = @study_plan.courses.includes(:localized_description).as_json(:only => [:id, :course_code, :credits], :methods => :localized_name, :root => false)
 
    respond_to do |format|
      format.json { render json: {
          study_plan: @study_plan,
          courses: scoped_courses,
          periods: periods
        }.to_json(root: false)
      }
    end
  end
  
end
