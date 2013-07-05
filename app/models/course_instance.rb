# Implementation of a course on a period. e.g. Programming 101 (Spring 2011)
class CourseInstance < ActiveRecord::Base

  #  create_table "course_instances", :force => true do |t|
  #    t.integer "abstract_course_id", :null => false
  #    t.integer "period_id",          :null => false
  #    t.integer "length"
  #  end

  # members
  #  - abstract_course
  #  - period
  #  - lenght


  belongs_to :abstract_course
  belongs_to :period


  def dbg_name
    return "%s %s" % [ abstract_course.code, period.name('en') ]
  end

  def end_date
    prd = length > 1 ? period.find_next_periods( length - 1 ).last : period
    prd.ends_at
  end

  def period_name( locale )
    period.name( locale )
  end

end
