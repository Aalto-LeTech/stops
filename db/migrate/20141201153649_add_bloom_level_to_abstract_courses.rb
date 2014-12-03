class AddBloomLevelToAbstractCourses < ActiveRecord::Migration
  def change
    add_column :abstract_courses, :bloom_level, :integer
  end
end
