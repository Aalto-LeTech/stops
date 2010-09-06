class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :curriculums do |t|
      t.integer :start_year
      t.integer :end_year
      t.string :name
    end
    
    create_table :courses do |t|
      t.string :code
      t.float :credits
      t.references :curriculum, :null => false
    end
    
    create_table :course_descriptions do |t|
      t.string :course_code, :null => false
      t.string :locale
      t.string :name, :null => false
    end
    
    create_table :profiles do |t|
      t.references :curriculum, :null => false
      t.integer :position, :default => 1
    end
    
    create_table :profile_descriptions do |t|
      t.references :profile
      t.string :locale
      t.string :name, :null => false
    end
    
#     create_table :areas do |t|
#       t.integer :position, :null => false
#     end
#     
#     create_table :area_descriptions do |t|
#       t.references :area
#       t.string :locale
#       t.string :name
#       t.text :description
#     end
    
    
    create_table :skill_levels do |t|
      t.integer :level, :null => false
      t.string :locale
      t.string :name
      t.text :definition
      t.text :keywords
      t.text :example
    end
    
    create_table :skills do |t|
      t.references :course
      t.integer :position
      t.integer :level
      t.float :credits
    end
    
    create_table :skill_descriptions do |t|
      t.references :skill
      t.string :locale
      t.text :description
    end
    
    # Course - course prereqs
    create_table :course_prereqs do |t|
      t.integer :course_id
      t.integer :prereq_id
      t.integer :requirement
    end
    
    # Skill - skill prereqs
    create_table :skill_prereqs do |t|
      t.integer :skill_id
      t.integer :prereq_id
      t.integer :requirement
    end
    
    # Which skills belong to which profile
    create_table :profiles_skills, :id => false do |t|
      t.references :profile
      t.references :skill
    end

    # Which skills belong to which course
    create_table :courses_skills, :id => false do |t|
      t.references :course
      t.references :skill
    end

    
    # Courses that are direct prereqs of profiles
    create_table :profile_courses do |t|
      t.references :profile
      t.references :course
      t.integer :requirement
    end
  end

  def self.down
    drop_table :profile_courses
    drop_table :courses_skills
    drop_table :profiles_skills
    drop_table :skill_prereqs
    drop_table :course_prereqs
    drop_table :skill_descriptions
    drop_table :skills
    drop_table :skill_levels
#     drop_table :area_descriptions
#     drop_table :areas
    drop_table :profile_descriptions
    drop_table :profiles
    drop_table :course_descriptions
    drop_table :courses
    drop_table :curriculums
  end
end
