class AddIndicesToCompetenceNodes < ActiveRecord::Migration
  def change
    add_index "competence_descriptions", "competence_id"
    add_index "competence_nodes", "abstract_course_id"
    add_index "competence_nodes", "parent_competence_id"
    add_index "course_descriptions", "abstract_course_id"
    add_index "roles", "user_id"
    add_index "treatments", "studentnumber"
  end
end
