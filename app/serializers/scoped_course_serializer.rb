class ScopedCourseSerializer < ActiveModel::Serializer

  attributes :id,
             :abstract_course_id,
             :credits,
             :studyplan_path

  def studyplan_path
    studyplan_course_path(object.id)
  end

end
