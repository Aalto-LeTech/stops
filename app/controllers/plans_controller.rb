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
  #       "curriculum_id": 3,
  #       "study_plan_courses": [
  #         {"period_id": 42, "scoped_course_id": 41},
  #         {"period_id": 44, "scoped_course_id": 60},
  #         ...
  #       ]
  #     },
  #     "courses": [
  #       {"course_code":"MS-A0001", "id":10, "abstract_course_id": 10, "credits":  5, "localized_name":"Matriisilaskenta", "prereq_ids": [11,15,...]},
  #       {"course_code":"MS-A0101", "id":11, "abstract_course_id": 11, "credits": 10, "localized_name":"Differentiaalilaskenta", "prereq_ids": [62,78,...]},
  #       ...
  #     ],
  #     "course_instances": [
  #       {"abstract_course_id": 10, "lenght": 2, "period_id": 4},
  #       ...
  #     ],
  #     "periods": [
  #       {"id": 25, "number": 4, "localized_name": "2009 II syksy", "begins_at": "2009-11-01", "ends_at": "2009-12-31"},
  #       {"id": 26, "number": 0, "localized_name": "2010 III kevat", "begins_at": "2010-01-01", "ends_at": "2010-02-28"},
  #       ...
  #     ],
  #     "passed_courses": [
  #       {"abstract_course_id": 179, "course_instance_id": 2711, "grade": 4, "id": 13}
  #       {"abstract_course_id": 189, "course_instance_id": 2811, "grade": 5, "id": 14}
  #       ...
  #     ],
  #     "current_period_id": 25
  #   }
  def show
    authorize! :read, @study_plan
    # FIXME: move relevant_periods to StudyPlan

    periods = @user.relevant_periods.includes( :localized_description )
    scoped_courses = @study_plan.courses.includes( [:localized_description, :prereqs] )

    # Get course instances
    abstract_course_ids = scoped_courses.map { |scoped_course| scoped_course.abstract_course_id }
    course_instances = CourseInstance.where( abstract_course_id: abstract_course_ids )

    periods_json = periods.as_json(
      only:     [:id, :number, :begins_at, :ends_at],
      methods:  [:localized_name],
      root:     false
    )

    scoped_courses_json = scoped_courses.as_json(
      only:     [:id, :abstract_course_id, :course_code, :credits],
      methods:  [:localized_name, :prereq_ids],
      root:     false
    )

    instances_json = course_instances.as_json(
      only:     [:id, :abstract_course_id, :period_id, :length],
      root:     false
    )

    passed_courses_json = @user.passed_courses.as_json(
      only:     [:id, :abstract_course_id, :course_instance_id, :grade],
      root:     false
    )

    # TODO: load competences

    respond_to do |format|
      format.json { render json: {
          study_plan: @study_plan,
          courses: scoped_courses_json,
          periods: periods_json,
          course_instances: instances_json,
          passed_courses: passed_courses_json,
          current_period_id: Period.current.id
        }.to_json( root: false )
      }
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
    accepted = @study_plan.update_from_json(params[:plan_courses]) if params[:plan_courses]

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
      format.js { render :json => {:status => :ok, :accepted => accepted} }
    end

  end

end
