class User < ActiveRecord::Base

  acts_as_authentic do |c|
    c.login_field = :studentnumber
    #c.validate_password_field = false
    c.validate_email_field = false
  end


  #validates_uniqueness_of :login #, :allow_nil => true
  validates_uniqueness_of :studentnumber #, :allow_nil => true
  #validates :first_study_period, :presence => true


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

  validates_presence_of :study_plan
  before_create { |user| user.build_study_plan }


  # The student's first period of study
  belongs_to :first_study_period,
             :class_name => 'Period'


  # User courses
  has_many :user_courses,
           :uniq => true,
           :dependent => :destroy


  def admin?
    self.admin
  end


  def staff?
    self.staff
  end

end
