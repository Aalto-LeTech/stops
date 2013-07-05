class AddIndices < ActiveRecord::Migration
  def change
    add_index "study_plans", "user_id"
    add_index "competence_nodes", "type"
    add_index "course_descriptions", "scoped_course_id"
    add_index "periods", "begins_at"
    add_index "course_instances", "abstract_course_id"
  end

end
