# Competence profile
class Profile < ActiveRecord::Base

  has_many :profile_descriptions, :dependent => :destroy
  
  # Prerequisite courses
  has_many :profile_courses, :dependent => :destroy
  has_many :courses, :through => :profile_courses, :source => :scoped_course, :order => 'code'
  
  has_many :strict_prereqs, :through => :profile_courses, :source => :scoped_course, :order => 'code', :conditions => "requirement = #{STRICT_PREREQ}"
  has_many :supporting_prereqs, :through => :profile_courses, :source => :scoped_course, :order => 'code', :conditions => "requirement = #{SUPPORTING_PREREQ}"
  
  # Skills provided by this profile
  # In practice, one skill belongs to only one profile. However, a join table is needed because skills can also belong to courses.
  has_and_belongs_to_many :skills
  
  # Users who have chosen this profile
  #has_many :user_profiles, :dependent => :destroy
  
  
  def name(locale)
    description = ProfileDescription.where(:profile_id => self.id, :locale => locale.to_s).first
    description ? description.name : ''
  end
  
  
  # returns an array of arrays of courses
  def semesters
    # put all courses and their recursive prereqs in the Level
    levels = Array.new
    level = self.courses_recursive
    
    begin
      # Create a list of courses that depend on some course on this level
      future_courses = Hash.new
      level.each do |course|
        course.prereq_to.each do |future_course|
          future_courses[future_course.id] = future_course
        end
      end
      
      # Move future courses to the next level
      next_level = Array.new
      level.each_with_index do |course, index|
        if future_courses.has_key?(course.id)
          level[index] = nil    # Remove from this level
          next_level << course   # Add to the next level
        end
      end
      
      levels << level
      level = next_level
    end while level.size > 0
    
    return levels
  end
  
  
  
  # Returns all courses and their prereqs, recursively
  def courses_recursive
    courses = Hash.new
    
    self.strict_prereqs.each do |prereq|
      add_course(courses, prereq)
    end

    courses.values
  end
  
  # Adds a course and its prereqs recursively to the given courses collection. If a course belongs to a prereq cycle, it is added to the cycles collection.
  def add_course(courses, course)
    # Do not follow branches that have already been handled
    return if courses.has_key?(course.id)
    
    # Add this course to the list
    courses[course.id] = course
    
    # Add pereqs of this course to the list
    course.strict_prereqs.each do |prereq|
      self.add_course(courses, prereq)
    end
  end
  
  
  
end
