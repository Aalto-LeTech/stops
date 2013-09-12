class DropUnusedTables < ActiveRecord::Migration
  def up
    drop_table :competence_courses_cache
    drop_table :temp_courses
  end
end
