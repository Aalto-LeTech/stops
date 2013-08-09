ThinkingSphinx::Index.define :scoped_course, :with => :active_record do
  # fields
  indexes course_code
  #indexes localized_description(:name), :as => :course_name
  #indexes skill_descriptions.description, :as => :skill_descriptions

  # attributes
  has :id, :as => :scoped_course_id
  has :abstract_course_id
end
