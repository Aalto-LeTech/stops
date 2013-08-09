ThinkingSphinx::Index.define :user, :with => :active_record do
  # fields
  indexes studentnumber
  indexes name

  # attributes
  has :id, :as => :user_id
  has :created_at
end
