class SkillSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :localized_name

end
