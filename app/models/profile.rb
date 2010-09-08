# Competence profile
class Profile < ActiveRecord::Base

  has_many :profile_descriptions, :dependent => :destroy
  
  # Prerequisite courses
  has_many :profile_courses, :dependent => :destroy
  has_many :courses, :through => :profile_courses, :source => :course, :order => 'code'
  
  has_many :strict_prereqs, :through => :profile_courses, :source => :course, :order => 'code', :conditions => "requirement = #{STRICT_PREREQ}"
  has_many :supporting_prereqs, :through => :profile_courses, :source => :course, :order => 'code', :conditions => "requirement = #{SUPPORTING_PREREQ}"
  
  # Skills provided by this profile
  # In practice, one skill belongs to only one profile. However, a join table is needed because skills can also belong to courses.
  has_and_belongs_to_many :skills
  
  
  def name(locale)
    description = ProfileDescription.find(:first,  :conditions => { :profile_id => self.id, :locale => locale.to_s })
    description ? description.name : ''
  end
  
  
  # returns an array of arrays of courses
  def semesters
    # put all courses and their recursive prereqs in the Level
    levels = Array.new
    level = self.ordered_courses
    
    begin
      # Create a list of courses that depend on some course on this level
      future_courses = Hash.new
      level.each do |course|
        course.prereq_to.each do |future_course|
          future_courses[future_course.id] = future_course
        end
      end
      
      puts "Level has #{level.size} courses which depend on #{future_courses.size} courses"
      
      # Move future courses to the next level
      next_level = Array.new
      level.each_with_index do |course, index|
        if future_courses.has_key?(course.id)
          level[index] = nil    # Remove from this level
          next_level << course   # Add to the next level
        end
      end
      
      puts "Moved #{next_level.size} courses to the next level"
      puts
      
      levels << level
      level = next_level
    end while level.size > 0
    
    return levels
  end
  
  
  
  # Returns all courses and their prereqs that form this profile
  def ordered_courses
    courses = Hash.new
    
    self.strict_prereqs.each do |prereq|
      add_course(courses, prereq)
    end

    #return Course.sort(courses.values)
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
