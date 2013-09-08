class RenameCoursePrereq < ActiveRecord::Migration
  def up
    rename_column :course_prereqs_cache, :scoped_course_id, :competence_node_id
    rename_column :course_prereqs_cache, :scoped_prereq_id, :prereq_id
    rename_table :course_prereqs_cache, :node_prereqs_cache
  end

  def down
    rename_column :node_prereqs_cache, :competence_node_id, :scoped_course_id
    rename_column :course_prereqs_cache, :prereq_id, :scoped_prereq_id
    rename_table :node_prereqs_cache, :course_prereqs_cache
  end
end
