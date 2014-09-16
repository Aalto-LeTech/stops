class AddPublishedToCurriculums < ActiveRecord::Migration
  def change
    add_column :curriculums, :published, :boolean, :default => false
  end
end
