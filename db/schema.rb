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

ActiveRecord::Schema.define(:version => 20140226151135) do

  create_table "abstract_courses", :force => true do |t|
    t.string  "code",        :null => false
    t.integer "min_credits"
    t.integer "max_credits"
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

  create_table "competence_descriptions", :force => true do |t|
    t.integer "competence_id", :null => false
    t.string  "locale"
    t.string  "name",          :null => false
    t.text    "description"
    t.integer "term_id"
  end

  add_index "competence_descriptions", ["competence_id", "locale"], :name => "index_competence_descriptions_on_competence_id_and_locale", :unique => true
  add_index "competence_descriptions", ["competence_id"], :name => "index_competence_descriptions_on_competence_id"
  add_index "competence_descriptions", ["term_id"], :name => "index_competence_descriptions_on_term_id"

  create_table "competence_nodes", :force => true do |t|
    t.string   "type"
    t.integer  "credits"
    t.integer  "level"
    t.integer  "abstract_course_id"
    t.integer  "curriculum_id",                           :null => false
    t.string   "course_code"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.integer  "parent_competence_id"
    t.text     "contact"
    t.string   "language"
    t.string   "instructors"
    t.boolean  "graduate_course"
    t.text     "changing_topic"
    t.string   "period"
    t.text     "comments"
    t.integer  "recommended_period"
    t.integer  "min_credits"
    t.integer  "position"
    t.boolean  "locked",               :default => false, :null => false
    t.text     "supporting_regex"
    t.integer  "term_id"
  end

  add_index "competence_nodes", ["abstract_course_id", "curriculum_id"], :name => "index_competence_nodes_on_abstract_course_id_and_curriculum_id"
  add_index "competence_nodes", ["abstract_course_id"], :name => "index_competence_nodes_on_abstract_course_id"
  add_index "competence_nodes", ["parent_competence_id"], :name => "index_competence_nodes_on_parent_competence_id"
  add_index "competence_nodes", ["term_id"], :name => "index_competence_nodes_on_term_id"
  add_index "competence_nodes", ["type"], :name => "index_competence_nodes_on_type"

  create_table "course_descriptions", :force => true do |t|
    t.string  "locale"
    t.string  "name",               :null => false
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
    t.integer "abstract_course_id", :null => false
    t.text    "noppa_url"
    t.text    "oodi_url"
    t.text    "period_info"
    t.text    "default_period"
  end

  add_index "course_descriptions", ["abstract_course_id"], :name => "index_course_descriptions_on_abstract_course_id"

  create_table "course_instances", :force => true do |t|
    t.integer "abstract_course_id",                :null => false
    t.integer "period_id",                         :null => false
    t.integer "length",             :default => 1, :null => false
  end

  add_index "course_instances", ["abstract_course_id", "period_id"], :name => "index_course_instances_on_abstract_course_id_and_period_id", :unique => true
  add_index "course_instances", ["abstract_course_id"], :name => "index_course_instances_on_abstract_course_id"

  create_table "curriculums", :force => true do |t|
    t.integer "start_year"
    t.integer "end_year"
    t.string  "name"
    t.integer "term_id"
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

  create_table "node_prereqs_cache", :force => true do |t|
    t.integer "competence_node_id", :null => false
    t.integer "prereq_id",          :null => false
    t.integer "requirement"
  end

  add_index "node_prereqs_cache", ["competence_node_id", "requirement"], :name => "index_course_prereqs_on_scoped_course_id_and_requirement"
  add_index "node_prereqs_cache", ["competence_node_id"], :name => "index_course_prereqs_on_scoped_course_id"
  add_index "node_prereqs_cache", ["prereq_id", "requirement"], :name => "index_course_prereqs_on_scoped_prereq_id_and_requirement"
  add_index "node_prereqs_cache", ["prereq_id"], :name => "index_course_prereqs_on_scoped_prereq_id"

  create_table "period_descriptions", :force => true do |t|
    t.integer "period_id", :null => false
    t.string  "locale"
    t.string  "name",      :null => false
    t.string  "symbol",    :null => false
  end

  add_index "period_descriptions", ["period_id", "locale"], :name => "index_period_descriptions_on_period_id_and_locale", :unique => true

  create_table "periods", :force => true do |t|
    t.integer "number",    :null => false
    t.date    "begins_at", :null => false
    t.date    "ends_at",   :null => false
  end

  add_index "periods", ["begins_at"], :name => "index_periods_on_begins_at"

  create_table "plan_competences", :force => true do |t|
    t.integer "study_plan_id",                              :null => false
    t.integer "competence_id",                              :null => false
    t.integer "included_scoped_course_ids", :default => [], :null => false, :array => true
  end

  add_index "plan_competences", ["study_plan_id", "competence_id"], :name => "index_study_plan_competences_on_study_plan_id_and_competence_id", :unique => true
  add_index "plan_competences", ["study_plan_id"], :name => "index_study_plan_competences_on_study_plan_id"

  create_table "plan_courses", :force => true do |t|
    t.integer "study_plan_id",                           :null => false
    t.integer "scoped_course_id"
    t.integer "competence_ref_count", :default => 1,     :null => false
    t.integer "course_instance_id"
    t.boolean "manually_added",       :default => false, :null => false
    t.integer "period_id"
    t.float   "credits",                                 :null => false
    t.integer "length"
    t.boolean "custom",               :default => false, :null => false
    t.integer "abstract_course_id",                      :null => false
    t.integer "grade",                :default => 0,     :null => false
    t.string  "course_code"
    t.integer "competence_node_id"
  end

  add_index "plan_courses", ["study_plan_id"], :name => "index_study_plan_courses_on_study_plan_id"

  create_table "roles", :force => true do |t|
    t.integer "user_id",   :null => false
    t.integer "target_id"
    t.string  "type"
    t.string  "role"
  end

  add_index "roles", ["user_id"], :name => "index_roles_on_user_id"

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
    t.text    "name"
    t.integer "term_id"
  end

  add_index "skill_descriptions", ["skill_id", "locale"], :name => "index_skill_descriptions_on_skill_id_and_locale", :unique => true
  add_index "skill_descriptions", ["skill_id"], :name => "index_skill_descriptions_on_skill_id"
  add_index "skill_descriptions", ["term_id"], :name => "index_skill_descriptions_on_term_id"

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
    t.integer "term_id"
  end

  add_index "skill_prereqs", ["prereq_id", "requirement"], :name => "index_skill_prereqs_on_prereq_id_and_requirement"
  add_index "skill_prereqs", ["prereq_id"], :name => "index_skill_prereqs_on_prereq_id"
  add_index "skill_prereqs", ["skill_id", "requirement"], :name => "index_skill_prereqs_on_skill_id_and_requirement"
  add_index "skill_prereqs", ["skill_id"], :name => "index_skill_prereqs_on_skill_id"
  add_index "skill_prereqs", ["term_id"], :name => "index_skill_prereqs_on_term_id"

  create_table "skills", :force => true do |t|
    t.integer "position",           :default => 0, :null => false
    t.integer "level"
    t.float   "credits"
    t.integer "competence_node_id",                :null => false
    t.string  "icon"
    t.integer "term_id"
  end

  add_index "skills", ["competence_node_id"], :name => "index_skills_on_competence_node_id"
  add_index "skills", ["term_id"], :name => "index_skills_on_term_id"

  create_table "study_plans", :force => true do |t|
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "user_id"
    t.integer  "curriculum_id",   :null => false
    t.integer  "first_period_id"
    t.integer  "last_period_id"
  end

  add_index "study_plans", ["user_id"], :name => "index_study_plans_on_user_id"

  create_table "survey_answers", :force => true do |t|
    t.integer  "survey_id",     :null => false
    t.integer  "user_id",       :null => false
    t.string   "studentnumber"
    t.string   "login"
    t.text     "payload",       :null => false
    t.datetime "created_at"
  end

  create_table "terms", :force => true do |t|
    t.integer "start_year"
    t.integer "end_year"
  end

  create_table "treatments", :force => true do |t|
    t.string  "studentnumber",                :null => false
    t.integer "treatment",     :default => 0, :null => false
  end

  add_index "treatments", ["studentnumber"], :name => "index_treatments_on_studentnumber"

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
    t.integer  "first_study_period_id"
    t.boolean  "staff",                                :default => false
    t.integer  "failed_login_count",                   :default => 0,     :null => false
    t.integer  "treatment"
  end

  add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["studentnumber"], :name => "index_users_on_studentnumber", :unique => true

end
