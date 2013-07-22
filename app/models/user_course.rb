# Join model that connects user to a course -- ie. courses that a user has passed
class UserCourse < ActiveRecord::Base

  #  create_table "user_courses", :force => true do |t|
  #    t.integer "user_id",            :null => false
  #    t.integer "abstract_course_id", :null => false
  #    t.integer "course_instance_id"
  #    t.integer "grade"
  #    t.float   "credits"
  #  end

  # members
  #  -> user
  #  -> abstract_course
  #  -> course_instance
  #  -> course_instance -> period
  #  -> course_instance -> length
  #  - grade
  #  - credits


  belongs_to :user
  belongs_to :course_instance
  belongs_to :abstract_course


  has_one :period,
          :through => :course_instance


  def course_code
    abstract_course.code
  end


  def end_date
    course_instance.end_date
  end


  def period_id
    course_instance.nil? ? nil : course_instance.period_id
  end


  def localized_period_name
    course_instance.localized_period_name
  end

end
