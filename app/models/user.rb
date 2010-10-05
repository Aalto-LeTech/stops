class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :remember_me

  
  # Plan
  has_and_belongs_to_many :profiles, :join_table => 'user_profiles', :uniq => true
  
  has_many :user_courses
  has_many :courses, :through => :user_courses, :uniq => true
  
  
  def add_profile(profile)
    return if profiles.exists?(profile.id)
      
    profiles << profile
    
    # Calculate union of existing and new courses, without duplicates
    courses_array = self.courses | profile.courses_recursive
    self.courses = courses_array
    
    #courses << profile.courses_recursive
  end
  
  


end
