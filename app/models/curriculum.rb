class Curriculum < ActiveRecord::Base

  validates_presence_of :start_year
  validates_presence_of :end_year
  validates_uniqueness_of :start_year
  validates_uniqueness_of :end_year
  
  has_many :profiles, :dependent => :destroy
  has_many :courses, :dependent => :destroy

  # Returns a human-readable representation, e.g. "2010" or "2010-2011"
  def name
    return '' if self.new_record?
    
    if self.end_year > self.start_year
      return "#{self.start_year} — #{self.end_year}"
    else
      return self.start_year
    end
  end

  
  # Returns all courses and their prereqs that form this profile
  def detect_cycles
    cycles = Array.new
    
    self.courses.each do |course|
      puts "Top level #{course.code}"
      #course = self.courses
      courses = Hash.new
      stack = Array.new
      add_course(course, course, courses, cycles, stack) unless courses.has_key?(course.id)
    end
    
    return cycles
  end
  
  # Adds a course and its prereqs recursively to the given courses collection. If a course belongs to a prereq cycle, it is added to the cycles collection.
  def add_course(start, course, courses, cycles, stack)
    if courses.has_key?(course.id)
      return
    end

    courses[course.id] = course
    
    stack.push(course)
    
    # Add pereqs of this course to the list
    course.strict_prereqs.each do |prereq|
      if prereq == start
        cycles << stack.clone
        stack.pop
        return
      end
      
      #puts "Proceeding to a prereq of #{course.code}"
      self.add_course(start, prereq, courses, cycles, stack)
    end
    
    stack.pop
    
    #puts "Returning from #{course.code}"
    
  end
end
