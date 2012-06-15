# Course that is not scoped to a specific curriculum or period.
class AbstractCourse < ActiveRecord::Base

  has_many :course_descriptions, :dependent => :destroy
  has_many :scoped_courses, :dependent => :destroy      # Courses in curriculums. e.g. "Course X-0.1010 according to the 2005 study guide"
  has_many :course_instances, :dependent => :destroy    # Course implementations, e.g. "Course X-0.1010 (spring 2011)"
  
  # Users who have chosen this course
  has_many :user_courses, :dependent => :destroy
  
  has_many :course_descriptions_with_locale, :class_name => "CourseDescription", 
           :conditions => proc { "locale = '#{I18n.locale}'" }
  
  def get_name(locale)
    description = CourseDescription.where(:abstract_course_id => self.id, :locale => locale.to_s).first
    description ? description.name : ''
  end

  
  # Returns periods on which this course is arranged
  def periods
    raise NotImplementedError, "AbstractCourse::periods not implemented"
  end
  
  # Returns CourseInstances
  def instances
    raise NotImplementedError, "AbstractCourse::instances not implemented"
  end
  
  # Returns the scoped course associated with this abstract course and the given curriculum
  # curriculum: Curriculum object or id
  def scoped_course(curriculum)
    if curriculum.is_a?(Numeric)
      curriculum_id = curriculum
    elsif curriculum.is_a?(Curriculum)
      curriculum_id = curriculum.id
    else
      raise ArgumentError("AbstractCourse::scoped_course needs a Curriculum object or id")
    end
    
    ScopedCourse.where(:curriculum_id => curriculum_id, :abstract_course_id => self.id).first
  end
end
