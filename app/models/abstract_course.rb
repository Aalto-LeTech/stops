# Course that is not scoped to a specific curriculum or period.
class AbstractCourse < ActiveRecord::Base

  #  create_table "abstract_courses", :force => true do |t|
  #    t.string "code"
  #  end

  # members
  #  - code
  #  - scoped_courses
  #  - course_instances
  #  - periods


  has_many :scoped_courses, :dependent => :destroy      # Courses in curriculums. e.g. "Course X-0.1010 according to the 2005 study guide"
  has_many :course_instances, :dependent => :destroy    # Course implementations, e.g. "Course X-0.1010 (spring 2011)"

  has_many  :periods,
            :through  => :course_instances

  #accepts_nested_attributes_for :scoped_courses

  # Make sure that nested ScopedCourses created at the same time get the same course code
#   before_create do |abstract_course|
#     abstract_course.scoped_courses.each do |scoped_course|
#       scoped_course.course_code = abstract_course.code
#     end
#   end

#   def get_name(locale)
#     description = CourseDescription.where(:abstract_course_id => self.id, :locale => locale.to_s).first
#     description ? description.name : ''
#   end

  # Returns CourseInstances
  def instances
    # FIXME!
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

  # Sets all ScopedCourses to point to the correct AbstractCourses. Creates AbstractCourses as necessary.
  def self.fix_abstract_courses
    # Load AbstractCourses to indexes
    abstract_courses_by_id = {}
    abstract_courses_by_code = {}
    AbstractCourse.find_each do |abstract_course|
      abstract_courses_by_id[abstract_course.id] = abstract_course
      abstract_courses_by_code[abstract_course.code] = abstract_course
    end
    
    # Chech every ScopedCourse
    ScopedCourse.find_each do |scoped_course|
      abstract_course = abstract_courses_by_id[scoped_course.abstract_course_id]
      
      # If abstract_course is missing or wrong, fix it
      if !abstract_course || abstract_course.code != scoped_course.course_code
        abstract_course = abstract_courses_by_code[scoped_course.course_code]
        
        # If suitable AbstractCourse does not exist, create it
        unless abstract_course
          abstract_course = AbstractCourse.create(:code => scoped_course.course_code)
          abstract_courses_by_id[abstract_course.id] = abstract_course
          abstract_courses_by_code[abstract_course.code] = abstract_course
        end
      
        scoped_course.abstract_course_id = abstract_course.id
        scoped_course.save
      end
    end
    
  end
  
  def self.create_random_instances
    periods = Period.order(:begins_at).all
    
    AbstractCourse.find_each do |abstract_course|
      period_number = rand(4)
      length = rand(2) + 1
    
      periods.each do |period|
        if period.number == period_number
          CourseInstance.create(:abstract_course_id => abstract_course.id, :period_id => period.id, :length => length)
        end
      end
    
    end
    
  end

  # Returns course name by curriculum
  def name( curriculum, locale )
    scoped_course = scoped_course( curriculum )
    scoped_course.nil? ? nil : scoped_course.name( locale )
  end

  # Returns credits by curriculum
  def credits( curriculum )
    scoped_course = self.scoped_course( curriculum )
    scoped_course.nil? ? nil : scoped_course.credits
  end

  # Returns the length of instance in given period or nil if unknown
  def length( period )
    course_instance = course_instances.where( period_id: period.id ).first
    course_instance.nil? ? nil : course_instance.length
  end

end
