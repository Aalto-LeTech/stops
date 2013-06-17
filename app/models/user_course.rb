# Join model that connects user to a course -- ie. courses that a user has passed
class UserCourse < ActiveRecord::Base

  belongs_to :user
  belongs_to :course_instance

  has_one :abstract_course,
          :through => :course_instance


  def passed?
    grade && grade > 0
  end

end
