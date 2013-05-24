# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20130517060457) do

  create_table "abstract_courses", :force => true do |t|
    t.string "code"
  end

  add_index "abstract_courses", ["code"], :name => "index_abstract_courses_on_code", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "comment_id"
    t.integer  "commentable_id",   :null => false
    t.string   "commentable_type", :null => false
    t.text     "comment"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "competence_courses_cache", :id => false, :force => true do |t|
    t.integer "competence_id",    :null => false
    t.integer "scoped_course_id", :null => false
    t.integer "requirement"
  end

  add_index "competence_courses_cache", ["competence_id", "requirement"], :name => "index_competence_courses_on_competence_id_and_requirement"
  add_index "competence_courses_cache", ["competence_id"], :name => "index_competence_courses_on_competence_id"

  create_table "competence_descriptions", :force => true do |t|
    t.integer "competence_id", :null => false
    t.string  "locale"
    t.string  "name",          :null => false
    t.text    "description"
  end

  add_index "competence_descriptions", ["competence_id", "locale"], :name => "index_competence_descriptions_on_competence_id_and_locale", :unique => true

  create_table "competence_nodes", :force => true do |t|
    t.string   "type"
    t.integer  "credits"
    t.integer  "level"
    t.integer  "abstract_course_id"
    t.integer  "curriculum_id"
    t.string   "course_code"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "parent_competence_id"
    t.text     "contact"
    t.string   "language"
    t.string   "instructors"
    t.boolean  "graduate_course"
    t.text     "changing_topic"
    t.string   "period"
    t.text     "comments"
  end

  add_index "competence_nodes", ["abstract_course_id", "curriculum_id"], :name => "index_competence_nodes_on_abstract_course_id_and_curriculum_id"

  create_table "course_descriptions", :force => true do |t|
    t.string  "locale"
    t.string  "name",             :null => false
    t.integer "scoped_course_id", :null => false
    t.string  "department"
    t.text    "grading_scale"
    t.text    "alternatives"
    t.text    "prerequisites"
    t.text    "outcomes"
    t.text    "content"
    t.text    "assignments"
    t.text    "grading_details"
    t.text    "materials"
    t.text    "replaces"
    t.text    "other"
    t.text    "comments"
  end

  create_table "course_instances", :force => true do |t|
    t.integer "abstract_course_id", :null => false
    t.integer "period_id",          :null => false
    t.integer "length"
  end

  add_index "course_instances", ["abstract_course_id", "period_id"], :name => "index_course_instances_on_abstract_course_id_and_period_id", :unique => true

  create_table "course_prereqs_cache", :force => true do |t|
    t.integer "scoped_course_id", :null => false
    t.integer "scoped_prereq_id", :null => false
    t.integer "requirement"
  end

  add_index "course_prereqs_cache", ["scoped_course_id", "requirement"], :name => "index_course_prereqs_on_scoped_course_id_and_requirement"
  add_index "course_prereqs_cache", ["scoped_course_id"], :name => "index_course_prereqs_on_scoped_course_id"
  add_index "course_prereqs_cache", ["scoped_prereq_id", "requirement"], :name => "index_course_prereqs_on_scoped_prereq_id_and_requirement"
  add_index "course_prereqs_cache", ["scoped_prereq_id"], :name => "index_course_prereqs_on_scoped_prereq_id"

  create_table "curriculums", :force => true do |t|
    t.integer "start_year"
    t.integer "end_year"
    t.string  "name"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "invitations", :force => true do |t|
    t.string   "token",      :null => false
    t.string   "type"
    t.string   "email"
    t.integer  "target_id"
    t.datetime "created_at"
    t.date     "expires_at"
  end

  add_index "invitations", ["token"], :name => "index_invitations_on_token"

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

  create_table "roles", :force => true do |t|
    t.integer "user_id",   :null => false
    t.integer "target_id"
    t.string  "type"
    t.string  "role"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

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
    t.integer "position"
    t.integer "level"
    t.float   "credits"
    t.integer "competence_node_id", :null => false
  end

  create_table "study_plan_competences", :force => true do |t|
    t.integer "study_plan_id",                              :null => false
    t.integer "competence_id",                              :null => false
    t.integer "included_scoped_course_ids", :default => [], :null => false, :array => true
  end

  add_index "study_plan_competences", ["study_plan_id", "competence_id"], :name => "index_study_plan_competences_on_study_plan_id_and_competence_id", :unique => true
  add_index "study_plan_competences", ["study_plan_id"], :name => "index_study_plan_competences_on_study_plan_id"

  create_table "study_plan_courses", :force => true do |t|
    t.integer "study_plan_id",                           :null => false
    t.integer "scoped_course_id",                        :null => false
    t.integer "competence_ref_count", :default => 1,     :null => false
    t.integer "course_instance_id"
    t.boolean "manually_added",       :default => false
    t.integer "grade"
  end

  add_index "study_plan_courses", ["study_plan_id", "scoped_course_id"], :name => "index_study_plan_courses_on_study_plan_id_and_scoped_course_id", :unique => true
  add_index "study_plan_courses", ["study_plan_id"], :name => "index_study_plan_courses_on_study_plan_id"

  create_table "study_plans", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "user_id"
  end

  create_table "temp_courses", :force => true do |t|
    t.integer  "curriculum_id",   :null => false
    t.text     "contact"
    t.string   "code"
    t.string   "name_fi"
    t.string   "name_en"
    t.string   "name_sv"
    t.integer  "credits"
    t.string   "department"
    t.string   "language"
    t.string   "instructors"
    t.text     "grading_scale"
    t.boolean  "graduate_course"
    t.text     "changing_topic"
    t.text     "alternatives"
    t.string   "period"
    t.text     "prerequisites"
    t.text     "outcomes"
    t.text     "content"
    t.text     "assignments"
    t.text     "grading_details"
    t.text     "materials"
    t.text     "replaces"
    t.text     "other"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.text     "comments"
  end

  add_index "temp_courses", ["curriculum_id"], :name => "index_temp_courses_on_curriculum_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "studentnumber"
    t.string   "name"
    t.string   "email",                 :limit => 320
    t.string   "locale",                :limit => 5,   :default => "fi"
    t.boolean  "admin",                                :default => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token",                                       :null => false
    t.integer  "login_count",                          :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "curriculum_id"
    t.integer  "first_study_period_id"
    t.boolean  "staff",                                :default => false
    t.integer  "failed_login_count",                   :default => 0,     :null => false
  end

  add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["studentnumber"], :name => "index_users_on_studentnumber", :unique => true

end
