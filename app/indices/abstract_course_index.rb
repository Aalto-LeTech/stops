ThinkingSphinx::Index.define :abstract_course, :with => :active_record do
  # fields
  indexes code
  indexes course_descriptions.name, :as => :course_name
  #indexes localized_description(:name), :as => :course_name
  #indexes skill_descriptions.description, :as => :skill_descriptions

  # attributes
  has :id, :as => :abstract_course_id
end
