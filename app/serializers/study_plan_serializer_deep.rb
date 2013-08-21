class StudyPlanSerializerDeep < StudyPlanSerializer

  attributes :competences
#             :abstract_courses,
#             :scoped_courses,
#             :skills,
#             :plan_courses,
#             :course_instances,
#             :periods


  def competences
    ApplicationController::srlze object.competences, options
  end

  def abstract_courses
    ApplicationController::srlze object.abstract_courses.includes(:localized_description), options
  end

  def scoped_courses
    ApplicationController::srlze object.scoped_courses, options
  end

  def skills
    ApplicationController::srlze object.skills.includes(:localized_description), options
  end

  def plan_courses
    ApplicationController::srlze object.plan_courses, options
  end

  def course_instances
    ApplicationController::srlze object.course_instances, options
  end

  def periods
    ApplicationController::srlze object.periods.includes(:localized_description), options
  end

end
