class StudyPlanSerializerDeep < StudyPlanSerializer

  attributes :competences,
             :abstract_courses,
             :scoped_courses,
             :skills,
             :plan_courses,
             :course_instances,
             :periods

#  has_many :competences
#  has_many
#  has_many :scoped_courses

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
    object.skills.includes(:localized_description)
  end

  def plan_courses
    object.plan_courses
  end

  def course_instances
    object.course_instances
  end

  def periods
    object.periods.includes(:localized_description)
  end

end
