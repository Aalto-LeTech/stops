class UserSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :name,
             :studentnumber

  has_one    :study_plan

end
