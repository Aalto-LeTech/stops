class CreateStudyPlans < ActiveRecord::Migration
  def up
    create_table :study_plans do |t|
      t.timestamps
      t.integer 'user_id'
    end

    remove_index :user_courses,     :name => :index_user_courses_on_user_id
    remove_index :user_competences, :name => :index_user_competences_on_user_id

    drop_table :user_courses
    drop_table :user_competences

    create_table :study_plan_courses do |t|
      t.integer 'study_plan_id',                            :null => false
      t.integer "scoped_course_id",                         :null => false
      t.integer 'competence_ref_count', :default => 1,      :null => false
      t.integer "course_instance_id"
      t.boolean "manually_added",       :default => false
      t.integer "grade"
    end

    create_table :study_plan_competences do |t|
      t.integer 'study_plan_id',                                :null => false
      t.integer "competence_id",                                :null => false
      t.integer 'included_scoped_course_ids', :default => '{}', :null => false, :array => true
    end

    add_index "study_plan_courses", ["study_plan_id"],                      :name => "index_study_plan_courses_on_study_plan_id"
    add_index "study_plan_competences", ["study_plan_id"],                  :name => "index_study_plan_competences_on_study_plan_id"
    add_index "study_plan_courses", ["study_plan_id", "scoped_course_id"],  :name => "index_study_plan_courses_on_study_plan_id_and_scoped_course_id", :unique => true
    add_index "study_plan_competences", ["study_plan_id", "competence_id"], :name => "index_study_plan_competences_on_study_plan_id_and_competence_id", :unique => true
  
    # Make sure each User has a StudyPlan
    User.pluck(:id).each do |user_id|
      StudyPlan.create :user_id => user_id
    end

  end


  def down
    drop_table :study_plans

    remove_index :study_plan_courses,     :name => :index_study_plan_courses_on_study_plan_id
    remove_index :study_plan_competences, :name => :index_study_plan_competences_on_study_plan_id
    remove_index :study_plan_courses,     :name => :index_study_plan_courses_on_study_plan_id_and_scoped_course_id
    remove_index :study_plan_competences, :name => :index_study_plan_competences_on_study_plan_id_and_competence_id

    drop_table :study_plan_courses
    drop_table :study_plan_competences

    create_table "user_courses", :force => true do |t|
      t.integer 'user_id',                              :null => false
      t.integer "scoped_course_id",                     :null => false
      t.integer "course_instance_id"
      t.boolean "manually_added",    :default => false
      t.integer "grade"
    end

    create_table "user_competences", :id => false, :force => true do |t|
      t.integer 'user_id',        :null => false
      t.integer "competence_id",  :null => false
    end

    add_index "user_courses", ["user_id"],     :name => "index_user_courses_on_user_id"
    add_index "user_competences", ["user_id"], :name => "index_user_competences_on_user_id"
  end
end
