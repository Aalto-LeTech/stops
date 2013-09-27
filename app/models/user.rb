class User < ActiveRecord::Base

  acts_as_authentic do |c|
    c.login_field = :studentnumber
    #c.validate_password_field = false
    c.validate_email_field = false
  end

  #validates_uniqueness_of :login #, :allow_nil => true
  #validates_uniqueness_of :studentnumber #, :allow_nil => true

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :name,
                  :studentnumber,
                  :locale,
                  :password,
                  :password_confirmation,
                  :remember_me

  # Plan
  has_one :study_plan, :dependent => :destroy

  # The student's first period of study
  belongs_to :first_study_period,
             :class_name => 'Period'

  def admin?
    self.admin
  end

  def staff?
    self.staff
  end

  def create_study_plan(curriculum_id)
    first_period = self.first_study_period || Period.find(DEFAULT_FIRST_PERIOD_ID) #Period.current
    last_period = Period.find_by_date(first_period.begins_at - 1 + 365 * INITIAL_STUDY_PLAN_TIME_IN_YEARS)

    self.study_plan = StudyPlan.create(
      user_id:          self.id,
      curriculum_id:    curriculum_id,
      first_period_id:  first_period.id,
      last_period_id:   last_period.id
    )
  end

end
