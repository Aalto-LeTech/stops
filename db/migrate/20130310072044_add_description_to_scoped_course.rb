class AddDescriptionToScopedCourse < ActiveRecord::Migration
  def up
    drop_table :profile_descriptions
    rename_table :course_prereqs, :course_prereqs_cache
    
    add_column :course_descriptions, :scoped_course_id, :integer, :null => false
    remove_column :course_descriptions, :abstract_course_id
    
    add_column :course_descriptions, :department,      :string
    add_column :course_descriptions, :grading_scale,   :text
    add_column :course_descriptions, :alternatives,    :text
    add_column :course_descriptions, :prerequisites,   :text
    add_column :course_descriptions, :outcomes,        :text
    add_column :course_descriptions, :content,         :text
    add_column :course_descriptions, :assignments,     :text
    add_column :course_descriptions, :grading_details, :text
    add_column :course_descriptions, :materials,       :text
    add_column :course_descriptions, :replaces,        :text
    add_column :course_descriptions, :other,           :text
    add_column :course_descriptions, :comments,        :text
    
    add_column :competence_nodes, :contact, :text
    add_column :competence_nodes, :language, :string
    add_column :competence_nodes, :instructors, :string
    add_column :competence_nodes, :graduate_course, :boolean
    add_column :competence_nodes, :changing_topic, :text
    add_column :competence_nodes, :period, :string
  end
  
  def down
    create_table :profile_descriptions do |t|
      t.references :profile, :null => false
      t.string :locale
      t.string :name, :null => false
      t.text :description
    end
    add_index(:profile_descriptions, [:profile_id, :locale], :unique => true)
    
    rename_table :course_prereqs_cache, :course_prereqs
    
    add_column :course_descriptions, :abstract_course_id, :integer, :null => false
    remove_column :course_descriptions, :scoped_course_id
    
    remove_column :course_descriptions, :department,      :string
    remove_column :course_descriptions, :grading_scale,   :text
    remove_column :course_descriptions, :alternatives,    :text
    remove_column :course_descriptions, :prerequisites,   :text
    remove_column :course_descriptions, :outcomes,        :text
    remove_column :course_descriptions, :content,         :text
    remove_column :course_descriptions, :assignments,     :text
    remove_column :course_descriptions, :grading_details, :text
    remove_column :course_descriptions, :materials,       :text
    remove_column :course_descriptions, :replaces,        :text
    remove_column :course_descriptions, :other,           :text
    remove_column :course_descriptions, :comments,        :text
    
    remove_column :competence_nodes, :contact, :text
    remove_column :competence_nodes, :language, :string
    remove_column :competence_nodes, :instructors, :string
    remove_column :competence_nodes, :graduate_course, :boolean
    remove_column :competence_nodes, :changing_topic, :text
    remove_column :competence_nodes, :period, :string
  end
end
