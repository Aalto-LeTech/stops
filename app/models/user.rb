class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.login_field = :studentnumber
    #c.validate_password_field = false
    c.validate_email_field = false
  end

  #validates_uniqueness_of :login #, :allow_nil => true
  validates_uniqueness_of :studentnumber #, :allow_nil => true
  validates :first_study_period, :presence => true

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :name,
                  :studentnumber,
                  :locale,
                  :password,
                  :password_confirmation,
                  :remember_me,
                  :curriculum_id   # FIXME to be removed?

  # Plan
  has_one :study_plan, :dependent => :destroy
  
  validates_presence_of :study_plan
  before_create { |user| user.build_study_plan }

  # The student's first period of study
  belongs_to :first_study_period,
             :class_name => 'Period'

  has_many :user_courses,
           :uniq => true,
           :dependent => :destroy

#  has_many  :user_courses,
#            :uniq => true,
#            :dependent => :destroy

#  has_many  :passed_courses,
#            :through => :user_courses,
#            :source => :scoped_course,
#            :dependent => :destroy

#  has_many  :passed_courses,
#            :through => :user_courses,
#            :uniq => true,
#            :dependent => :destroy

  def admin?
    self.admin
  end

  def staff?
    self.staff
  end

  # Returns the periods between the beginning of the user's studies and the expected graduation
  def relevant_periods
    Period.current.find_next_periods(35) unless self.first_study_period
    self.first_study_period.find_next_periods(35) # 5 periods * 7 years
  end

  # Returns the matching user course
  def get_user_course( abstract_course )
    self.user_courses.where( abstract_course: abstract_course ).first
  end

  # Returns the grade for the given course
  def get_grade( abstract_course )
    user_course = self.get_user_course( abstract_course )
    user_course.nil? ? nil : user_course.grade
  end

  # Returns true if the user has passed (grade > 0) the given course and false
  # otherwise
  def passed?( abstract_course )
    abstract_course.nil? ? false : self.user_courses.where(
        'abstract_course_id = ? AND grade > ?', abstract_course.id, 0
        ).exists?
  end

  # Returns passed courses
  def passed_courses
    self.user_courses.where( 'grade > ?', 0 ).sort { |a, b| a.end_date <=> b.end_date }
  end

end
