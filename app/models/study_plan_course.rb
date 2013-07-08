# Join model that connects study plan to a course
class StudyPlanCourse < ActiveRecord::Base

  #  create_table "study_plan_courses", :force => true do |t|
  #    t.integer "study_plan_id",                           :null => false
  #    t.integer "scoped_course_id",                        :null => false
  #    t.integer "competence_ref_count", :default => 1,     :null => false
  #    t.boolean "manually_added",       :default => false
  #    t.integer "course_instance_id"
  #    t.integer "period_id"
  #  end

  # members                  notes
  #  - study_plan
  #  - scoped_course
  #  - manually_added
  #  - course_instance       field to be removed
  #  - period


  belongs_to :study_plan
  belongs_to :scoped_course
  belongs_to :course_instance
  belongs_to :period

  def course_code
    scoped_course.course_code
  end

  def localized_name
    scoped_course.localized_name
  end

  def credits
    scoped_course.credits
  end

  # Returns the length of the course in periods and nil if unknown
  def length_or_one
    length = scoped_course.length( period )
    length.nil? ? 1 : length
  end

  # Returns the period name or nil
  def localized_period_name
    period.nil? ? nil : period.localized_name
  end

end
