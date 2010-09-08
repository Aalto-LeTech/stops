# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100826130740) do

  create_table "course_descriptions", :force => true do |t|
    t.integer "course_id", :null => false
    t.string  "locale"
    t.string  "name",      :null => false
  end

  create_table "course_prereqs", :force => true do |t|
    t.integer "course_id",   :null => false
    t.integer "prereq_id",   :null => false
    t.integer "requirement"
  end

  create_table "courses", :force => true do |t|
    t.string  "code"
    t.float   "credits"
    t.integer "curriculum_id", :null => false
  end

  create_table "courses_skills", :id => false, :force => true do |t|
    t.integer "course_id", :null => false
    t.integer "skill_id",  :null => false
  end

  create_table "curriculums", :force => true do |t|
    t.integer "start_year"
    t.integer "end_year"
    t.string  "name"
  end

  create_table "profile_courses", :force => true do |t|
    t.integer "profile_id",  :null => false
    t.integer "course_id",   :null => false
    t.integer "requirement"
  end

  create_table "profile_descriptions", :force => true do |t|
    t.integer "profile_id", :null => false
    t.string  "locale"
    t.string  "name",       :null => false
  end

  create_table "profiles", :force => true do |t|
    t.integer "curriculum_id",                :null => false
    t.integer "position",      :default => 1
  end

  create_table "profiles_skills", :id => false, :force => true do |t|
    t.integer "profile_id", :null => false
    t.integer "skill_id",   :null => false
  end

  create_table "skill_descriptions", :force => true do |t|
    t.integer "skill_id",    :null => false
    t.string  "locale"
    t.text    "description"
  end

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

  create_table "skills", :force => true do |t|
    t.integer "course_id"
    t.integer "position"
    t.integer "level"
    t.float   "credits"
  end

  create_table "user_courses", :force => true do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.integer "grade"
  end

  create_table "user_profiles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "profile_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                                       :null => false
    t.string   "studentnumber"
    t.string   "name"
    t.string   "email",                     :limit => 320
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.boolean  "admin",                                    :default => false
    t.string   "locale",                    :limit => 5,   :default => "fi"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "curriculum_id"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
