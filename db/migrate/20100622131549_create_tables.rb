class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :curriculums do |t|
      t.integer :start_year
      t.integer :end_year
      t.string :name
    end
    add_column :users, :curriculum_id, :integer
    
    create_table :periods do |t|
      t.integer :number, :null => false     #1,2,3,4,1,2,3,4,..
      t.date :begins_at
      t.date :ends_at
    end
    
    create_table :period_descriptions do |t|
      t.references :period, :null => false
      t.string :locale
      t.string :name, :null => false
    end
    add_index(:period_descriptions, [:period_id, :locale], :unique => true)
    
    create_table :abstract_courses do |t|
      t.string :code
    end
    add_index(:abstract_courses, :code, :unique => true)
    
    create_table :course_descriptions do |t|
      t.references :abstract_course, :null => false
      t.string :locale
      t.string :name, :null => false
    end
    add_index(:course_descriptions, [:abstract_course_id, :locale], :unique => true)
    
    create_table :scoped_courses do |t|
      t.references :abstract_course, :null => false
      t.references :curriculum, :null => false
      t.string :code
      t.float :credits
    end
    add_index(:scoped_courses, [:abstract_course_id, :curriculum_id], :unique => true)
    add_index(:scoped_courses, :curriculum_id)
    
    create_table :course_instances do |t|
      t.references :abstract_course, :null => false
      t.references :period, :null => false
      t.integer :length                       # length in periods
    end
    add_index(:course_instances, [:abstract_course_id, :period_id], :unique => true)
    
    create_table :profiles do |t|
      t.references :curriculum, :null => false
    end
    
    create_table :profile_descriptions do |t|
      t.references :profile, :null => false
      t.string :locale
      t.string :name, :null => false
      t.text :description
    end
    add_index(:profile_descriptions, [:profile_id, :locale], :unique => true)
    
    create_table :competences do |t|
      t.references :profile, :null => false
      t.integer :level, :default => 1
      t.float :credits, :null => false, :default => 0
    end
    add_index(:competences, :profile_id)
    
    create_table :competence_descriptions do |t|
      t.references :competence, :null => false
      t.string :locale
      t.string :name, :null => false
      t.text :description
    end
    add_index(:competence_descriptions, [:competence_id, :locale], :unique => true)
    
    # Bloom levels
    create_table :skill_levels do |t|
      t.integer :level, :null => false
      t.string :locale
      t.string :name
      t.text :definition
      t.text :keywords
      t.text :example
    end
    
    create_table :skills do |t|
      t.references :skillable, :polymorphic => true, :null => false  # can belong to course or competence
      t.integer :position
      t.integer :level
      t.float :credits
    end
    #add_index(:skills, :scoped_course_id)
    
    create_table :skill_descriptions do |t|
      t.references :skill, :null => false
      t.string :locale
      t.text :description
    end
    add_index(:skill_descriptions, [:skill_id, :locale], :unique => true)
    
    # Course - course prereqs
    create_table :course_prereqs do |t|
      t.integer :scoped_course_id, :null => false
      t.integer :scoped_prereq_id, :null => false
      t.integer :requirement
    end
    add_index(:course_prereqs, :scoped_course_id)
    add_index(:course_prereqs, [:scoped_course_id, :requirement])
    add_index(:course_prereqs, :scoped_prereq_id)
    add_index(:course_prereqs, [:scoped_prereq_id, :requirement])
    
    # Skill - skill prereqs
    create_table :skill_prereqs do |t|
      t.integer :skill_id, :null => false
      t.integer :prereq_id, :null => false
      t.integer :requirement
    end
    add_index(:skill_prereqs, :skill_id)
    add_index(:skill_prereqs, [:skill_id, :requirement])
    add_index(:skill_prereqs, :prereq_id)
    add_index(:skill_prereqs, [:prereq_id, :requirement])
    
    # Courses that are direct prereqs of profiles
    create_table :competence_courses, :id => false do |t|
      t.references :competence, :null => false
      t.references :scoped_course, :null => false
      t.integer :requirement
    end
    add_index(:competence_courses, :competence_id)
    add_index(:competence_courses, [:competence_id, :requirement])
  end

  def self.down
    drop_table :competence_courses
    #drop_table :competence_skills
    #drop_table :course_skills
    drop_table :skill_prereqs
    drop_table :course_prereqs
    drop_table :skill_descriptions
    drop_table :skills
    drop_table :skill_levels
    drop_table :competence_descriptions
    drop_table :competences
    drop_table :profiles
    drop_table :profile_descriptions
    drop_table :course_instances
    drop_table :scoped_courses
    drop_table :course_descriptions
    drop_table :abstract_courses
    drop_table :period_descriptions
    drop_table :periods
    drop_table :curriculums
  end
end
