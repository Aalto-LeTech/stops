class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :locale, :password, :password_confirmation, :remember_me

  
  # Plan
  has_and_belongs_to_many :profiles, :join_table => 'user_profiles', :uniq => true
  
  has_many :user_courses, :dependent => :destroy
  has_many :courses, :through => :user_courses, :source => :scoped_course, :uniq => true
  
  
  def add_profile(profile)
    # Dont't do anything if user already has this profile
    return if profiles.exists?(profile.id)
    
    profiles << profile
    
    # Calculate union of existing and new courses, without duplicates
    courses_array = self.courses | profile.courses_recursive
    
    #profile.courses_recursive.each do |course|
      # courses_array << course.abstract_course unless courses_array.include? course.abstract_course
      # courses_array << course unless courses_array.include? course.abstract_course
    #end
    
    self.courses = courses_array
  end
  
  
  # Returns the periods between the beginning of the user's studies and the expected graduation
  def relevant_periods
    logger.warn "User::relevant_periods not implemented"
    Period.all
  end
  
end
