class ScopedCourseShortSerializer < ActiveModel::Serializer

  embed :ids, include: true

  attributes :id,
             :credits,
             :studyplan_path

  has_one    :abstract_course

  def studyplan_path
    studyplan_course_path(object.id)
  end

end
