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
  # Data is given minimally, only to build a description of the plan with some
  # abstraction.
  #
  # Example
  #    {
  #       "current_period_id" : 43,
  #       "periods" : [
  #          {
  #             "ends_at" : "2012-08-31",
  #             "begins_at" : "2012-06-01",
  #             "id" : 38,
  #             "localized_name" : "2012  kesä"
  #          },
  #          ...
  #       ],
  #       "courses" : [
  #          {
  #             "length" : null,
  #             "scoped_course" : {
  #                "prereq_ids" : [12, 13, ..., 99],
  #                "credits" : 5,
  #                "id" : 54
  #             },
  #             "abstract_course" : {
  #                "course_instances" : [
  #                   {
  #                      "length" : 2,
  #                      "period_id" : 4
  #                   },
  #                   ...
  #                ],
  #                "id" : 223,
  #                "localized_name" : "Tulevaisuuden rakennukset",
  #                "code" : "RAK-C3001"
  #             },
  #             "credits" : 5,
  #             "period_id" : 44
  #          }
  #       ],
  #       "competences" : [
  #          {
  #             "course_ids_recursive" : [45, 44, ..., 50],
  #             "localized_name" : "Kandi: Taidolliset kompetenssit"
  #          },
  #          ...
  #       ],
  #       "user_courses" : [
  #          {
  #             "credits" : 5,
  #             "abstract_course_id" : 228,
  #             "grade" : 1,
  #             "period_id" : 42
  #          },
  #          ...
  #       ]
  #    }
  #
  def show
    authorize! :read, @study_plan

    # Get periods, competences, user courses and study plan course data
    periods = @study_plan.periods.includes(:localized_description)
    competences = @study_plan.competences.includes([:localized_description, :courses])
    user_courses = @user.user_courses.includes(:course_instance)
    study_plan_courses = @study_plan.study_plan_courses.includes(
      [
        abstract_course: [:localized_description, :course_instances],
        scoped_course: [:prereqs]
      ]
    )

    # JSONify the data
    periods_json = periods.as_json(
      only: [:id, :begins_at, :ends_at],
      methods: [:localized_name],
      root: false
    )

    # TODO: Replace courses_recursive with a more efficient solution
    competences_json = competences.as_json(
      only: [],
      methods: [:localized_name, :course_ids_recursive],
      root: false
    )

    user_courses_json = user_courses.as_json(
      only: [:abstract_course_id, :grade, :credits],
      methods: [:period_id],
      root: false
    )

    study_plan_courses_json = study_plan_courses.as_json(
      only: [:period_id, :credits, :length],
      include: [
        {
          abstract_course: {
            only: [:id, :code],
            methods: [:localized_name],
            include: {
              course_instances: {
                only: [:period_id, :length]
              }
            }
          }
        },
        {
          scoped_course: {
            only: [:id, :credits],
            methods: [:prereq_ids]
          }
        }
      ],
      root: false
    )

    # Form and send the response
    respond_to do |format|
      format.json { render json: {
          periods: periods_json,
          competences: competences_json,
          user_courses: user_courses_json,
          courses: study_plan_courses_json,
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
