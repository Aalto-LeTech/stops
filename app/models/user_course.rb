# Join model that connects user to a course -- ie. courses that a user has passed
class UserCourse < ActiveRecord::Base

  #  create_table "user_courses", :force => true do |t|
  #    t.integer "user_id",            :null => false
  #    t.integer "abstract_course_id", :null => false
  #    t.integer "course_instance_id"
  #    t.integer "grade"
  #  end

  # members
  #  - user
  #  - abstract_course   via course_instance
  #  - course_instance
  #  - grade


  belongs_to :user
  belongs_to :course_instance

  has_one :abstract_course,
          :through => :course_instance


  def course_code
    abstract_course.code
  end

  def name( curriculum, locale )
    abstract_course.name( curriculum, locale )
  end

  def credits( curriculum )
    abstract_course.credits( curriculum )
  end

  def passed?
    grade && grade > 0
  end

  def end_date
    course_instance.end_date
  end

  def period_name( locale )
    course_instance.period_name( locale )
  end

end
