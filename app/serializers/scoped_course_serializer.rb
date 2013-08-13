class ScopedCourseSerializer < ScopedCourseShortSerializer
  #embed :ids, include: true

  has_many :skills
  has_many :prereqs, serializer: ScopedCourseShortSerializer
end
