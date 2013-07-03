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
  #     ],
  #     "current_period": 25
  #   }
  def show
    authorize! :read, @study_plan
    
    # FIXME: move relevant_periods to StudyPlan
    periods = @user.relevant_periods.includes(:localized_description).as_json(:only => [:id, :number], :methods => [:localized_name], :root => false)
    scoped_courses = @study_plan.courses.includes(:localized_description).as_json(:only => [:id, :course_code, :credits], :methods => :localized_name, :root => false)
 
    respond_to do |format|
      format.json { render json: {
          study_plan: @study_plan,
          courses: scoped_courses,
          periods: periods,
          current_period_id: Period.current.id,
        }.to_json(root: false)
      }
    end
  end
  
  # Expects parameter study_plan_courses with a JSON string:
  # [
  #   { "scoped_course_id": 71, "period_id": 30 },
  #   { "scoped_course_id": 25, "period_id": 32 },
  #   ...
  # ]
  def update
    authorize! :update, @study_plan
    # TODO: authentication

    @study_plan.update_from_json(params[:study_plan_courses]) if params[:study_plan_courses]
    
#     if params[:periods]
#       params[:periods].each do |user_course_id, period_id|
#         user_course = StudyPlanCourse.where(:id => user_course_id).first
#         next unless user_course
# 
#         user_course.period_id = period_id
#         user_course.save
#       end
#     end

    respond_to do |format|
      format.js { render :json => {:status => :ok} }
    end
    
  end
  
end
