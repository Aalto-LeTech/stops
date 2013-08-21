class AbstractCourseSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :code,
             :localized_name

end
