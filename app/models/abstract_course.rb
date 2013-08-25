# Course that is not scoped to a specific curriculum or period.
class AbstractCourse < ActiveRecord::Base

  #  create_table "abstract_courses", :force => true do |t|
  #    t.string "code"
  #  end

  # members
  #  - code
  #  <- localized_description = course_descriptions (name, locale, ...)
  #  <- scoped_courses
  #  <- course_instances
  #  <- study_plan_courses
  #  <- periods <- course_instances


  has_many :course_descriptions
  
  has_one :localized_description, :class_name => "CourseDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" }

  # Courses
  has_many :scoped_courses, :dependent => :destroy      # Courses in curriculums. e.g. "Course X-0.1010 according to the 2005 study guide"
  has_many :course_instances, :dependent => :destroy    # Course implementations, e.g. "Course X-0.1010 (spring 2011)"
  has_many :study_plan_courses, :dependent => :destroy  # Courses planned by students in their personal study plans

  # Periods
  has_many  :periods,
            :through  => :course_instances


  def localized_name
    desc = localized_description
    (desc && desc.name != "" ) ? desc.name : nil
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
      period_number += 1 if period_number >= 2  # Don't put courses on summer
      length = rand(2) + 1
      length = 1 if period_number == 1 || period_number == 4  # Length of the last periods can only be 1

      periods.each do |period|
        if period.number == period_number
          CourseInstance.create(:abstract_course_id => abstract_course.id, :period_id => period.id, :length => length)
        end
      end

    end

  end

end
