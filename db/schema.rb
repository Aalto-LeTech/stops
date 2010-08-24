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

ActiveRecord::Schema.define(:version => 20100622131549) do

  create_table "area_descriptions", :force => true do |t|
    t.integer "area_id"
    t.string  "locale"
    t.string  "name"
    t.text    "description"
  end

  create_table "areas", :force => true do |t|
    t.integer "position", :null => false
  end

  create_table "course_descriptions", :force => true do |t|
    t.string "course_code", :null => false
    t.string "locale"
    t.string "name",        :null => false
  end

  create_table "course_prereqs", :force => true do |t|
    t.integer "course_id"
    t.integer "prereq_id"
    t.integer "requirement"
  end

  create_table "courses", :force => true do |t|
    t.string  "code"
    t.float   "credits"
    t.integer "curriculum_id", :null => false
  end

  create_table "curriculums", :force => true do |t|
    t.integer "year"
    t.string  "name"
  end

  create_table "profile_courses", :force => true do |t|
    t.integer "profile_id"
    t.integer "course_id"
    t.integer "requirement"
  end

  create_table "profile_descriptions", :force => true do |t|
    t.integer "profile_id"
    t.string  "locale"
    t.string  "name",       :null => false
  end

  create_table "profile_skills", :force => true do |t|
    t.integer "profile_id"
    t.integer "skill_id"
    t.integer "area_id"
    t.integer "requirement"
  end

  create_table "profiles", :force => true do |t|
    t.integer "curriculum_id",                :null => false
    t.integer "position",      :default => 1
  end

  create_table "skill_descriptions", :force => true do |t|
    t.integer "skill_id"
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
    t.integer "skill_id"
    t.integer "prereq_id"
    t.integer "requirement"
  end

  create_table "skills", :force => true do |t|
    t.string  "course_code"
    t.integer "position"
    t.integer "level"
    t.float   "credits"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 320
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
