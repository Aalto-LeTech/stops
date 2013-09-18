class PlansController < ApplicationController

  before_filter :authenticate_user
  before_filter :load_plan

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


  def show
    authorize! :read, @study_plan

    # Form and send the response
    respond_to do |format|
      format.html { redirect_to studyplan_schedule_path }
      format.json { render json: as_hash(@study_plan) }
    end
  end


  # /plans/123.json returns the plan as JSON
  # Data is given minimally, only to build a description of the plan with some
  # abstraction.
  #
  # Example
  #    {
  #       "current_period_id" : 43,
  #       "periods" : [
  #          {
  #             "id" : 38,
  #             "localized_name" : "2012  kesä",
  #             "ends_at" : "2012-08-31",
  #             "begins_at" : "2012-06-01"
  #          },
  #          ...
  #       ],
  #       "courses" : [
  #          {
  #             "period_id" : 44,
  #             "credits" : 5,
  #             "length" : null,
  #             "abstract_course" : {
  #                "id" : 223,
  #                "code" : "RAK-C3001",
  #                "localized_name" : "Tulevaisuuden rakennukset",
  #                "course_instances" : [
  #                   {
  #                      "length" : 2,
  #                      "period_id" : 4
  #                   },
  #                   ...
  #                ]
  #             },
  #             "scoped_course" : {
  #                "id" : 54,
  #                "credits" : 5,
  #                "prereq_ids" : [12, 13, ..., 99]
  #             }
  #          }
  #       ],
  #       "competences" : [
  #          {
  #             "localized_name" : "Kandi: Taidolliset kompetenssit",
  #             "course_ids_recursive" : [45, 44, ..., 50]
  #          },
  #          ...
  #       ],
  #       "user_courses" : [
  #          {
  #             "abstract_course_id" : 228,
  #             "credits" : 5,
  #             "grade" : 1,
  #             "period_id" : 42
  #          },
  #          ...
  #       ]
  #    }
  #
  def old_schedule
    authorize! :read, @study_plan

    # Form and send the response
    respond_to do |format|
      format.html { redirect_to studyplan_schedule_path }
      format.json { render json: @study_plan.json_schedule.to_json( root: false ) }
    end
  end
  
  def summary
    authorize! :read, @study_plan
    
    respond_to do |format|
      format.json { render json: @study_plan.json_summary.to_json( root: false ) }
    end
  end

  # Expects parameter plan_courses with a JSON string:
  # [
  #   {"scoped_course_id": 71, "period_id": 1, "course_instance_id": 45},
  #   {"scoped_course_id": 35, "period_id": 2},
  #   {"scoped_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
  #   {"scoped_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
  #   ...
  # ]
  def update
    authorize! :update, @study_plan
    # TODO: authentication

    # Forward the data for the study_plan's update function which returns
    # feedback to be sent back.
    feedback = @study_plan.update_from_json(params[:json]) if params[:json]

    respond_to do |format|
      format.js { render :json => {:status => :ok, :feedback => feedback} }
    end

  end

end
