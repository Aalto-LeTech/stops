class PlanCourseSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :length,
             :credits,
             :grade,
             :manually_added,

             :abstract_course_id,
             :scoped_course_id,
             :course_instance_id,
             :period_id

#  has_one    :abstract_course
#  has_one    :scoped_course, serializer: ScopedCourseShortSerializer
#  has_one    :course_instance
#  has_one    :period

end
