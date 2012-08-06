class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.login_field = :studentnumber
    #c.validate_password_field = false
    c.validate_email_field = false
  end

  validates_uniqueness_of :login, :allow_nil => true
  validates_uniqueness_of :studentnumber, :allow_nil => true
  validates :first_study_period, :presence => true

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :name, 
                  :locale, 
                  :password, 
                  :password_confirmation, 
                  :remember_me, 
                  :curriculum_id

  # Plan
  has_and_belongs_to_many :competences, :join_table => 'user_competences', :uniq => true

  # The student's first period of study
  belongs_to :first_study_period, 
             :class_name => 'Period'

  has_many  :user_courses, 
            :dependent => :destroy

  has_many  :courses, 
            :through => :user_courses, 
            :source => :scoped_course, 
            :uniq => true

  has_many  :passed_courses, 
            :through => :user_courses, 
            :source => :scoped_course, 
            :uniq => true, 
            :conditions => "grade IS NOT NULL"

  has_many  :user_manual_courses, 
            :class_name => 'UserCourse', 
            :dependent => :destroy, 
            :conditions => {:manually_added => true}

  has_many  :manual_courses, 
            :through => :user_manual_courses, 
            :source => :scoped_course, 
            :uniq => true # manually added courses

  belongs_to :curriculum 

  def admin?
    self.admin
  end

  def passed?(course)
    passed_courses.include?(course.id)
  end

  def add_competence(competence)
    # Dont't do anything if user already has this profile
    return if has_competence?(competence)

    competences << competence

    # Calculate union of existing and new courses, without duplicates
    courses_array = self.courses | competence.courses_recursive

    #profile.courses_recursive.each do |course|
      # courses_array << course.abstract_course unless courses_array.include? course.abstract_course
      # courses_array << course unless courses_array.include? course.abstract_course
    #end

    self.courses = courses_array
  end

  # Removes the given profile and courses that are needed by it. Courses that are still needed by the remaining profiles, are not removed. Also, manually added courses are not reomved.
  def remove_competence(competence)
    # Remove profile
    competences.delete(competence)

    self.courses = needed_courses(self.competences).to_a
  end

  def has_competence?(competence)
    competences.include? competence
  end


  # Returns a list of courses than can be deleted if the given profile is dropped from the study plan
  def deletable_courses(competence)
    # Make an array of competences that user has after deleting the given competence
    remaining_competences = competences.clone
    remaining_competences.delete(competence)
    puts "#{competences.size} / #{remaining_competences.size}"

    # Make a list of courses that are needed by the remaining profiles
    needed_courses = needed_courses(remaining_competences)

    courses.to_set - needed_courses
  end

  # Returns a set of courses that are needed by the given competences
  # competences: a collection of competence objects
  def needed_courses(competences)
    # Make a list of courses that are needed by remaining profiles
    needed_courses = Set.new
    competences.each do |competence|
      needed_courses.merge(competence.courses_recursive)
    end

    # Add manually added courses to the list
    needed_courses.merge(manual_courses)
  end


  # Returns the periods between the beginning of the user's studies and the expected graduation
  def relevant_periods
    self.first_study_period.find_next_periods(35) # 5 periods * 7 years
  end

end
