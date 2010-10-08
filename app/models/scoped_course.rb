class ScopedCourse < ActiveRecord::Base

  belongs_to :abstract_course
  
  has_many :skills, :order => 'position', :dependent => :destroy #, :foreign_key => 'course_code', :primary_key => 'code'
  
  # Prerequisite courses of this course
  has_many :course_prereqs, :dependent => :destroy
  
  # Prerequisite skills of this course
  has_many :prereqs, :through => :course_prereqs, :source => :prereq, :order => 'requirement DESC, code'
  has_many :strict_prereqs, :through => :course_prereqs, :source => :prereq, :order => 'requirement DESC, code', :conditions => "requirement = #{STRICT_PREREQ}"
  has_many :supporting_prereqs, :through => :course_prereqs, :source => :prereq, :order => 'requirement DESC, code', :conditions => "requirement = #{SUPPORTING_PREREQ}"
  
  # Courses for which this is a prerequisite
  has_many :course_prereq_to, :class_name => 'CoursePrereq', :foreign_key => :scoped_prereq_id
  has_many :prereq_to, :through => :course_prereq_to, :source => :course, :order => 'code', :conditions => "requirement = #{STRICT_PREREQ}"
  
  
  def name(locale)
    description = CourseDescription.where(:abstract_course_id => self.abstract_course_id, :locale => locale.to_s).first
    description ? description.name : ''
  end


  # Returns -1 if the is a prereq of other, +1 if this is a prereq to other, otherwise 0.
  def <=>(other)
    if strict_prereqs.exists?(other)
      return 1
    elsif prereq_to.exists?(other)      
      return -1
    else
      return 0
    end
  end


  # returns an array of arrays of courses
  def self.semesters(courses)
    # put all courses and their recursive prereqs in the Level
    levels = Array.new
    level = courses
    
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
          level[index] = nil    # Remove from this level  FIXME: don't leave nils
          next_level << course   # Add to the next level
        end
      end
      
      levels << level
      level = next_level
    end while level.size > 0
    
    return levels
  end
  
  # Returns periods on which this course is arranged
  def periods
    raise NotImplementedError, "Course::periods not implemented"
  end
  
end
