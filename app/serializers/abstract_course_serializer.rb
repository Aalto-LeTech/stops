class AbstractCourseSerializer < ActiveModel::Serializer
  attributes :id,
             :code,
             :localized_name
end
