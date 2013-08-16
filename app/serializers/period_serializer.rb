class PeriodSerializer < ActiveModel::Serializer

  attributes :id,
             :begins_at,
             :ends_at,
             :number,
             :localized_name,
             :symbol

end
