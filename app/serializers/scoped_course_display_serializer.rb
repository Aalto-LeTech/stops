class ScopedCourseDisplaySerializer < ScopedCourseSerializer

  attributes :course_code,
             :localized_name

  has_many :skills
  has_many :prereqs, serializer: ScopedCourseShortSerializer

end
