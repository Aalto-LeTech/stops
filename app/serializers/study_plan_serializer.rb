class StudyPlanSerializer < ActiveModel::Serializer

  attributes :id,
             :user_id,
             :curriculum_id,
             :first_period_id,
             :last_period_id,
             :created_at,
             :updated_at

end
