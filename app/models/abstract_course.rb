class AbstractCourse < ActiveRecord::Base

  has_many :course_descriptions, :dependent => :destroy
  has_many :scoped_courses, :dependent => :destroy      # Courses in curriculums. e.g. "Course X-0.1010 according to the 2005 study guide"
  has_many :course_instances, :dependent => :destroy    # Actual implemented course where students enroll. 
  
  # Users who have chosen this course
  has_many :user_courses, :dependent => :destroy
  
  
  def name(locale)
    description = CourseDescription.where(:abstract_course_id => self.id, :locale => locale.to_s).first
    description ? description.name : ''
  end

  
  # Returns periods on which this course is arranged
  def periods
    raise NotImplementedError, "Course::periods not implemented"
  end
  
end
