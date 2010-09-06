class Course < ActiveRecord::Base

  has_many :course_descriptions, :dependent => :destroy
  
  has_many :skills, :order => 'position' #, :foreign_key => 'course_code', :primary_key => 'code'
  
  # Prerequisite courses of this course
  has_many :course_prereqs, :dependent => :destroy
  
  # Prerequisite skills of this course
  has_many :prereqs, :through => :course_prereqs, :source => :prereq, :order => 'requirement DESC, code'
  has_many :strict_prereqs, :through => :course_prereqs, :source => :prereq, :order => 'requirement DESC, code', :conditions => "requirement = #{STRICT_PREREQ}"
  has_many :supporting_prereqs, :through => :course_prereqs, :source => :prereq, :order => 'requirement DESC, code', :conditions => "requirement = #{SUPPORTING_PREREQ}"
  
  # Courses for which this is a prerequisite
  has_many :course_prereq_to, :class_name => 'CoursePrereq', :foreign_key => :prereq_id
  has_many :prereq_to, :through => :course_prereq_to, :source => :course, :order => 'code', :conditions => "requirement = #{STRICT_PREREQ}"
  
  
  
  def name(locale)
    description = CourseDescription.find(:first,  :conditions => { :course_id => self.id, :locale => locale.to_s })
    description ? description.name : ''
  end

  
end
