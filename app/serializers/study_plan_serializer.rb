class StudyPlanSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
#             :user_id,
#             :curriculum_id,
#             :first_period_id,
#             :last_period_id,
             :created_at,
             :updated_at

  has_one    :user
  has_one    :curriculum
  has_one    :first_period
  has_one    :last_period

  has_many   :plan_courses
  has_many   :competences

  has_many   :skills
  has_many   :abstract_courses
  has_many   :scoped_courses
  has_many   :course_instances
  has_many   :periods

  def skills
    object.skills.includes(:localized_description)
  end

  def abstract_courses
    object.abstract_courses.includes(:localized_description)
  end

  def competences
    object.competences.includes(
      :strict_prereq_courses =>
      [
        :abstract_course => :localized_description
      ]
    )
  end

  def plan_courses
    object.plan_courses.includes(
      :scoped_course =>
      [
        :abstract_course => :localized_description,
        :skills => :localized_description,
        :strict_prereq_courses =>
        #:prereqs =>
        [
          :abstract_course => :localized_description
        ]
      ],
      :course_instance =>
      [
      ],
      :period =>
      [
        :localized_description
      ]
    )
  end

  def periods
    object.periods.includes(:localized_description)
  end

end
