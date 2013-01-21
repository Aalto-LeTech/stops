class TempCourseComment < ActiveRecord::Migration
  
  def up
    add_column :temp_courses, :comments, :text
  end

  def down
    remove_column :temp_courses, :comments
  end
  
end
