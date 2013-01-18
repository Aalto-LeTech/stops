class CreateTempCourses < ActiveRecord::Migration
  def change
    create_table :temp_courses do |t|
      t.references :curriculum, :null => false
      t.text :contact
      t.string :code
      t.string :name_fi
      t.string :name_en
      t.string :name_sv
      t.integer :credits
      t.string :department
      t.string :language
      t.string :instructors
      t.text :grading_scale
      t.boolean :graduate_course
      t.text :changing_topic
      t.text :alternatives
      t.string :period
      t.text :prerequisites
      t.text :outcomes
      t.text :content
      t.text :assignments
      t.text :grading_details
      t.text :materials
      t.text :replaces
      t.text :other

      t.timestamps
    end
    add_index :temp_courses, :curriculum_id
  end
end
