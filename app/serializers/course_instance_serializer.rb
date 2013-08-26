class CourseInstanceSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :abstract_course_id,
             :period_id,
             :length

end
