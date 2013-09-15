class CreateSurveys < ActiveRecord::Migration
  def change
    create_table "survey_answers" do |t|
      t.integer  "survey_id",         :null => false
      t.integer  "user_id",           :null => false
      t.string   "studentnumber"
      t.string   "login"
      t.text     "payload",           :null => false
      t.datetime "created_at"
    end
  end
end
