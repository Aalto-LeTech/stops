class CourseInstanceSerializer < ActiveModel::Serializer

  attributes :id,
             :abstract_course_id,
             :period_id,
             :length

end
