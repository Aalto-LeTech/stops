class DropUserCourses < ActiveRecord::Migration
  def up
    drop_table :user_courses
  end

  def down
    create_table :user_courses do |t|
      t.references :user,              :null => false
      t.references :abstract_course,   :null => false
      t.references :course_instance
      t.integer    "grade"
      t.float      "credits"
    end
  end
end
