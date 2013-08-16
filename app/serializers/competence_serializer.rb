class CompetenceSerializer < ActiveModel::Serializer

  attributes :localized_name,
             :strict_prereqs

  def strict_prereqs
    object.strict_prereq_ids
  end

end
