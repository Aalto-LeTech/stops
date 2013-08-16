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
  def show
    authorize! :read, @study_plan

    #respond_with @study_plan
    #format.json { render json: response_json }
    # Form and send the response
    respond_to do |format|
      format.html { redirect_to studyplan_schedule_path }
      format.json { render json: as_hash(@study_plan, serializer: StudyPlanSerializerDeep) }
    end

#    data = JSON.parse(params[:json]) if params[:json]

#    y data
#    targets = data['targets']

#    if targets

#      response_data = {}

#      targets.each do |target|

#        if target == 'abstract_courses'
#          response_data[target] = as_hash(@study_plan.abstract_courses.includes(:localized_description).all)
#        elsif target == 'plan_courses'
#          response_data[target] = as_hash(@study_plan.plan_courses.all)
#        elsif target == 'skills'
#          response_data[target] = as_hash(@study_plan.skills.includes(:localized_description).all)
#        elsif target == 'scoped_courses'
#          response_data[target] = as_hash(@study_plan.scoped_courses.all)
#        elsif target == 'periods'
#          response_data[target] = as_hash(@study_plan.periods.includes(:localized_description).all)
#        elsif target == 'course_instances'
#          response_data[target] = as_hash(@study_plan.course_instances.all)
#        else
#          puts "Ignoring invalid target: #{target}!"
#          if not response_data['ignored']
#            response_data['ignored'] = []
#          end
#          response_data['ignored'] << target
#        end

#      end

#      response_data.each do |key, data|
#        puts "Sample data #{key}:"
#        if data
#          y data[0..1]
#        end
#      end

#    else
#      response_data = {
#        error: 'No targets given!'
#      }
#    end

#    response_json = response_data.to_json( root: false )

#    # Form and send the response (or redirect)
#    respond_to do |format|
#      format.html { redirect_to studyplan_schedule_path }
#      format.json { render json: response_json }
#    end
################################################################################

#    bundle = params[:bundle] if params[:bundle]

#    if bundle == 'schedule'

#      # Get periods, competences, user courses and plan course data
#      periods = @study_plan.periods.includes(:localized_description)
#      competences = @study_plan.competences.includes([:localized_description, :courses])
#      user_courses = @user.user_courses.includes(:course_instance)
#      plan_courses = @study_plan.plan_courses.includes(
#        [
#          abstract_course: [:localized_description, :course_instances],
#          scoped_course: [:prereqs]
#        ]
#      )

#      # JSONify the data
#      periods_data = periods.as_json(
#        only: [:id, :begins_at, :ends_at],
#        methods: [:localized_name],
#        root: false
#      )

#      # TODO: Replace courses_recursive with a more efficient solution
#      competences_data = competences.as_json(
#        only: [],
#        methods: [:localized_name, :course_ids_recursive],
#        root: false
#      )

#      user_courses_data = user_courses.as_json(
#        only: [:id, :abstract_course_id, :grade, :credits],
#        methods: [:period_id],
#        root: false
#      )

#      plan_courses_data = plan_courses.as_json(
#        only: [:id, :period_id, :credits, :length],
#        include: [
#          {
#            abstract_course: {
#              only: [:id, :code],
#              methods: [:localized_name],
#              include: {
#                course_instances: {
#                  only: [:period_id, :length]
#                }
#              }
#            }
#          },
#          {
#            scoped_course: {
#              only: [:id, :credits],
#              methods: [:prereq_ids]
#            }
#          }
#        ],
#        root: false
#      )

#      response_data = {
#        periods: periods_data,
#        competences: competences_data,
#        user_courses: user_courses_data,
#        plan_courses: plan_courses_data,
#      }

#    elsif bundle == 'all'

#      # Get periods, competences, user courses and plan course data
#      periods = @study_plan.periods.includes(:localized_description)
#      competences = @study_plan.competences.includes([:localized_description, :courses])
#      user_courses = @user.user_courses.includes(:course_instance)
#      plan_courses = @study_plan.plan_courses.includes(
#        [
#          abstract_course: [:localized_description, :course_instances],
#          scoped_course: [:prereqs]
#        ]
#      )

#      # JSONify the data
#      periods_data = periods.as_json(
#        only: [:id, :begins_at, :ends_at],
#        methods: [:localized_name],
#        root: false
#      )

#      # TODO: Replace courses_recursive with a more efficient solution
#      competences_data = competences.as_json(
#        only: [:id],
#        methods: [:localized_name, :course_ids_recursive],
#        root: false
#      )

#      plan_courses_data = plan_courses.as_json(
#        only: [:id, :period_id, :credits, :length],
#        include: [
#          {
#            abstract_course: {
#              only: [:id, :code],
#              methods: [:localized_name],
#              include: {
#                course_instances: {
#                  only: [:period_id, :length]
#                }
#              }
#            }
#          },
#          {
#            scoped_course: {
#              only: [:id, :credits],
#              methods: [:prereq_ids]
#            }
#          }
#        ],
#        root: false
#      )

#      response_data = {
#        periods: periods_data,
#        competences: competences_data,
#        user_courses: user_courses_data,
#        plan_courses: plan_courses_data,
#      }

#    elsif bundle == 'courses_with_ids_grades_and_periods'

#      plan_course_data = @study_plan.plan_courses.as_json(
#        only: [:id, :scoped_course_id, :abstract_course_id, :period_id],
#        root: false
#      )

#      grade_data = @user.user_courses.as_json(
#        only: [:abstract_course_id, :grade],
#        root: false
#      )

#      period_data = @study_plan.periods.includes(:localized_description).as_json(
#        only: [:id],
#        methods: [:localized_name],
#        root: false
#      )

#      response_data = {
#        plan_courses: plan_course_data,
#        grades: grade_data,
#        periods: period_data
#      }

#    else

#      throw 'Invalid bundle!'
#      #response_data = {
#      #  error: 'Invalid bundle!'
#      #}

#    end

#    response_json = response_data.to_json( root: false )

#    # Form and send the response
#    respond_to do |format|
#      format.html { redirect_to studyplan_schedule_path }
#      format.json { render json: response_json }
#    end
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
