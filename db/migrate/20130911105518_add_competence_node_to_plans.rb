class AddCompetenceNodeToPlans < ActiveRecord::Migration
  def up
    add_column :plan_courses, :course_code, :string
    add_column :plan_courses, :competence_node_id, :integer
    
    add_column :skill_descriptions, :name, :text
    execute "UPDATE skill_descriptions SET name=description"
    execute "UPDATE skill_descriptions SET description=NULL"
    
    add_column :competence_nodes, :recommended_period, :integer
    
    add_column :users, :treatment, :integer
    
    create_table :treatments do |t|
      t.string :studentnumber, :null => false
      t.integer :treatment, :default => 0, :null => false
    end
  end
  
  def down
    remove_column :plan_courses, :course_code
    remove_column :plan_courses, :competence_node_id
    
    execute "UPDATE skill_descriptions SET description=name"
    remove_column :skill_description, :name
        
    remove_column :scoped_course, :recommended_period
    
    remove_column :users, :treatment
    
    drop_table :treatments
  end
end
