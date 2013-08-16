class PeriodDescriptionSerializer < ActiveModel::Serializer

  attributes :id,
             :period_id,
             :name,
             :symbol

end
