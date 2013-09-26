# Join model that connects study plan to a course
class PlanCourse < ActiveRecord::Base

  # To note:
  #  - period: when 'course_instance_id' isn't nil the 'period_id' should equal
  #    the 'course_instance.period_id'
  #    Also, there can never be two course instances with the same abstract
  #    course in the same period
  #  - credits, custom: when the course isn't customized (custom == false),
  #    'credits' should equal the one's of its scoped course, and vice versa


  belongs_to :study_plan
  belongs_to :abstract_course
  belongs_to :scoped_course
  belongs_to :course_instance
  belongs_to :period


  # Localized descriptions
  has_one :localized_description, :class_name => "CourseDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" },
          :primary_key => :abstract_course_id,
          :foreign_key => :abstract_course_id

  has_one :localized_period_description, :class_name => "PeriodDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" },
          :primary_key => :period_id,
          :foreign_key => :period_id


  def course_code
    abstract_course.code
  end


  def localized_name
    desc = localized_description
    (desc && desc.name != "" ) ? desc.name : nil
  end


  # Return the prerequirement scoped course ids in an array
  def prereq_ids
    return [] unless scoped_course
    scoped_course.prereq_ids
  end

  # Returns an array of abstract_course_ids that are the direct prereqs of this planned course
  def abstract_prereq_ids
    return [] unless scoped_course
    scoped_course.strict_prereqs.collect { |scoped_course| scoped_course.abstract_course_id }
  end
  

  # Returns the length of the course in periods and nil if unknown
  def length_or_one
    length = scoped_course.length( period )
    length.nil? ? 1 : length
  end


  # Returns the period name or nil
  def localized_period_name
    localized_period_description.nil? ? '' : localized_period_description.name
  end

  # Returns the course's ending period
  def ending_period
    start_period = self.period
    length = self.length
    return nil if start_period.nil?
    return start_period if length.nil? or length <= 1
    return start_period.find_following(length).last
  end

end
