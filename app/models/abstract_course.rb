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
