class PeriodDescriptionSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :period_id,
             :name,
             :symbol

end
