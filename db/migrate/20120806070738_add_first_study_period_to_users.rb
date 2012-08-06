class AddFirstStudyPeriodToUsers < ActiveRecord::Migration

  def up
    change_table :users do |t|
      t.references :first_study_period
    end

    period = Period.find(24)
    User.all.each do |user|
      user.first_study_period = period
      user.save!
    end

  end

  def down
    change_table :users do |t|
      t.remove_references :first_study_period 
    end
  end
end
