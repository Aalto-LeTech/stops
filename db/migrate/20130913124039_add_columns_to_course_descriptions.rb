class AddColumnsToCourseDescriptions < ActiveRecord::Migration
  def change
    add_column :course_descriptions, :noppa_url, :text
    add_column :course_descriptions, :oodi_url, :text
    add_column :course_descriptions, :period_info, :text
    add_column :course_descriptions, :default_period, :text
  end
end
