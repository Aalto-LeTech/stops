class PeriodSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :begins_at,
             :ends_at,
             :number,
             :localized_name,
             :symbol

end
