class CompetenceSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :localized_name

  has_many   :strict_prereqs, serializer: ScopedCourseShortSerializer

#  def strict_prereqs
#    object.strict_prereq_ids
#  end

end
