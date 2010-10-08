# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100826130740) do

  create_table "abstract_courses", :force => true do |t|
    t.string "code"
  end

  add_index "abstract_courses", ["code"], :name => "index_abstract_courses_on_code", :unique => true

  create_table "course_descriptions", :force => true do |t|
    t.integer "abstract_course_id", :null => false
    t.string  "locale"
    t.string  "name",               :null => false
  end

  add_index "course_descriptions", ["abstract_course_id", "locale"], :name => "index_course_descriptions_on_abstract_course_id_and_locale", :unique => true

  create_table "course_instances", :force => true do |t|
    t.integer "abstract_course_id", :null => false
    t.integer "period_id",          :null => false
  end

  add_index "course_instances", ["abstract_course_id", "period_id"], :name => "index_course_instances_on_abstract_course_id_and_period_id", :unique => true

  create_table "course_prereqs", :force => true do |t|
    t.integer "scoped_course_id", :null => false
    t.integer "scoped_prereq_id", :null => false
    t.integer "requirement"
  end

  add_index "course_prereqs", ["scoped_course_id", "requirement"], :name => "index_course_prereqs_on_scoped_course_id_and_requirement"
  add_index "course_prereqs", ["scoped_course_id"], :name => "index_course_prereqs_on_scoped_course_id"
  add_index "course_prereqs", ["scoped_prereq_id", "requirement"], :name => "index_course_prereqs_on_scoped_prereq_id_and_requirement"
  add_index "course_prereqs", ["scoped_prereq_id"], :name => "index_course_prereqs_on_scoped_prereq_id"

  create_table "courses_skills", :id => false, :force => true do |t|
    t.integer "scoped_course_id", :null => false
    t.integer "skill_id",         :null => false
  end

  add_index "courses_skills", ["scoped_course_id"], :name => "index_courses_skills_on_scoped_course_id"

  create_table "curriculums", :force => true do |t|
    t.integer "start_year"
    t.integer "end_year"
    t.string  "name"
  end

  create_table "period_descriptions", :force => true do |t|
    t.integer "period_id", :null => false
    t.string  "locale"
    t.string  "name",      :null => false
  end

  add_index "period_descriptions", ["period_id", "locale"], :name => "index_period_descriptions_on_period_id_and_locale", :unique => true

  create_table "periods", :force => true do |t|
    t.integer "number",    :null => false
    t.date    "begins_at"
    t.date    "ends_at"
  end

  create_table "profile_courses", :force => true do |t|
    t.integer "profile_id",       :null => false
    t.integer "scoped_course_id", :null => false
    t.integer "requirement"
  end

  add_index "profile_courses", ["profile_id", "requirement"], :name => "index_profile_courses_on_profile_id_and_requirement"
  add_index "profile_courses", ["profile_id"], :name => "index_profile_courses_on_profile_id"

  create_table "profile_descriptions", :force => true do |t|
    t.integer "profile_id", :null => false
    t.string  "locale"
    t.string  "name",       :null => false
  end

  add_index "profile_descriptions", ["profile_id", "locale"], :name => "index_profile_descriptions_on_profile_id_and_locale", :unique => true

  create_table "profiles", :force => true do |t|
    t.integer "curriculum_id",                :null => false
    t.integer "position",      :default => 1
  end

  add_index "profiles", ["curriculum_id"], :name => "index_profiles_on_curriculum_id"

  create_table "profiles_skills", :id => false, :force => true do |t|
    t.integer "profile_id", :null => false
    t.integer "skill_id",   :null => false
  end

  add_index "profiles_skills", ["profile_id"], :name => "index_profiles_skills_on_profile_id"

  create_table "scoped_courses", :force => true do |t|
    t.integer "abstract_course_id", :null => false
    t.integer "curriculum_id",      :null => false
    t.string  "code"
    t.float   "credits"
    t.integer "length"
  end

  add_index "scoped_courses", ["abstract_course_id", "curriculum_id"], :name => "index_scoped_courses_on_abstract_course_id_and_curriculum_id", :unique => true
  add_index "scoped_courses", ["curriculum_id"], :name => "index_scoped_courses_on_curriculum_id"

  create_table "skill_descriptions", :force => true do |t|
    t.integer "skill_id",    :null => false
    t.string  "locale"
    t.text    "description"
  end

  add_index "skill_descriptions", ["skill_id", "locale"], :name => "index_skill_descriptions_on_skill_id_and_locale", :unique => true

  create_table "skill_levels", :force => true do |t|
    t.integer "level",      :null => false
    t.string  "locale"
    t.string  "name"
    t.text    "definition"
    t.text    "keywords"
    t.text    "example"
  end

  create_table "skill_prereqs", :force => true do |t|
    t.integer "skill_id",    :null => false
    t.integer "prereq_id",   :null => false
    t.integer "requirement"
  end

  add_index "skill_prereqs", ["prereq_id", "requirement"], :name => "index_skill_prereqs_on_prereq_id_and_requirement"
  add_index "skill_prereqs", ["prereq_id"], :name => "index_skill_prereqs_on_prereq_id"
  add_index "skill_prereqs", ["skill_id", "requirement"], :name => "index_skill_prereqs_on_skill_id_and_requirement"
  add_index "skill_prereqs", ["skill_id"], :name => "index_skill_prereqs_on_skill_id"

  create_table "skills", :force => true do |t|
    t.integer "scoped_course_id"
    t.integer "position"
    t.integer "level"
    t.float   "credits"
  end

  add_index "skills", ["scoped_course_id"], :name => "index_skills_on_scoped_course_id"

  create_table "user_courses", :force => true do |t|
    t.integer "user_id",            :null => false
    t.integer "abstract_course_id", :null => false
    t.integer "course_instance_id"
    t.integer "grade"
  end

  add_index "user_courses", ["user_id"], :name => "index_user_courses_on_user_id"

  create_table "user_profiles", :id => false, :force => true do |t|
    t.integer "user_id",    :null => false
    t.integer "profile_id", :null => false
  end

  add_index "user_profiles", ["user_id"], :name => "index_user_profiles_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login",                                                  :null => false
    t.string   "studentnumber"
    t.string   "name"
    t.string   "email",                               :default => "",    :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",    :null => false
    t.string   "password_salt",                       :default => "",    :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "locale",               :limit => 5,   :default => "fi"
    t.boolean  "admin",                               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "curriculum_id"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
