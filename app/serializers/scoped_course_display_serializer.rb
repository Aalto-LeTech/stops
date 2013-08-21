class ScopedCourseDisplaySerializer < ScopedCourseSerializer

  embed :ids, include: true

  attributes :id

#  has_one    :abstract_course

#  def studyplan_path
#    studyplan_course_path(object.id)
#  end

#  embed :ids, include: true

#  attributes :course_code,
#             :localized_name

#  has_many   :skills
#  has_many   :prereqs, serializer: ScopedCourseShortSerializer

end
