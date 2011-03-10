class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :locale, :password, :password_confirmation, :remember_me

  # Plan
  has_and_belongs_to_many :competences, :join_table => 'user_competences', :uniq => true
  
  has_many :user_courses, :dependent => :destroy
  has_many :courses, :through => :user_courses, :source => :scoped_course, :uniq => true
  
  belongs_to :curriculum
  
  
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
  
  # Removes the given profile and courses that are needed by it. Courses that are still needed by the remaining profiles, are not removed. Also, manually added courses are not reomved.
  def remove_profile(profile)
    # Remove profile
    profiles.delete(profile)
    
    # Make a list of courses that are needed by remaining profiles
    needed_courses = Set.new
    profiles.each do |profile|
      needed_courses.merge(profile.courses_recursive)
      
      puts "needed_courses.size: #{needed_courses.size}"
    end
    
    # TODO: add manually added courses to the list
    #needed_courses.merge(manual_courses)
    
    self.courses = needed_courses
  end
  

  # Returns a list of courses than can be deleted if the given profile is dropped from the study plan
  def deletable_courses(profile)
    # TODO
    # Make an array of profiles that user has after deleting the given profile
    #remaining_profiles = profiles.clone
    #remaining_profiles.delete(profile)
    
    # Make a list of courses that are needed by the remaining profiles
    
    []
  end
  
  # Returns the periods between the beginning of the user's studies and the expected graduation
  def relevant_periods
    logger.warn "User::relevant_periods not implemented"
    Period.all
  end
  
  
  
end
