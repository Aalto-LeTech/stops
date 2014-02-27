# Course that is not scoped to a specific curriculum or period.
class AbstractCourse < ActiveRecord::Base

  has_many :course_descriptions, :order => :locale
  
  has_one :localized_description, :class_name => "CourseDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" }

  # Courses
  has_many :scoped_courses, :dependent => :destroy      # Courses in terms. e.g. "Course X-0.1010 according to the 2005 study guide"
  has_many :course_instances, :dependent => :destroy    # Course implementations, e.g. "Course X-0.1010 (spring 2011)"
  has_many :plan_courses, :dependent => :destroy        # Courses planned by students in their personal study plans

  # Periods
  has_many  :periods,
            :through  => :course_instances


  def localized_name
    desc = localized_description
    (desc && desc.name != "") ? desc.name : nil
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

end
