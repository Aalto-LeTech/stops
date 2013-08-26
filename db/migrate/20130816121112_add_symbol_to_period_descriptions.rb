class AddSymbolToPeriodDescriptions < ActiveRecord::Migration

  def up
    add_column :period_descriptions, :symbol, :string, :null => false

    change_column :periods, :begins_at, :date, :null => false
    change_column :periods, :ends_at,   :date, :null => false

    change_column :plan_courses, :manually_added,     :boolean,  :default => false,  :null => false
    change_column :plan_courses, :credits,            :float,                        :null => false
    change_column :plan_courses, :custom,             :boolean,  :default => false,  :null => false
    change_column :plan_courses, :grade,              :integer,  :default => 0,      :null => false
    change_column :plan_courses, :abstract_course_id, :integer,                      :null => false
  end


  def down
    change_column :plan_courses, :manually_added,     :boolean,  :default => false,  :null => true
    change_column :plan_courses, :credits,            :float,                        :null => true
    change_column :plan_courses, :custom,             :boolean,  :default => false,  :null => true
    change_column :plan_courses, :grade,              :integer,  :default => nil,    :null => true
    change_column :plan_courses, :abstract_course_id, :integer,                      :null => true

    change_column :periods, :ends_at,   :null => true
    change_column :periods, :begins_at, :null => true
    remove_column :period_descriptions, :symbol
  end

end
