class PlanCourseSerializer < ActiveModel::Serializer

  attributes :id,
             :abstract_course_id,
             :scoped_course_id,
             :course_instance_id,
             :period_id,
             :length,
             :credits,
             :grade,
             :manually_added

end