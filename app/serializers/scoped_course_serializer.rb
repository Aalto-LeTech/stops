class ScopedCourseSerializer < ScopedCourseShortSerializer

  embed :ids, include: true

  has_many   :skills
  has_many   :strict_prereq_courses, serializer: ScopedCourseShortSerializer

end
