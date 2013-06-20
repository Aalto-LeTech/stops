# Implementation of a course on a period. e.g. Programming 101 (Spring 2011)
class CourseInstance < ActiveRecord::Base

  belongs_to :abstract_course
  belongs_to :period

end
