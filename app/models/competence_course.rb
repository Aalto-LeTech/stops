# Join model that connects competence profiles to prerequisite courses
class CompetenceCourse < ActiveRecord::Base

  belongs_to :competence
  belongs_to :scoped_course
  
end
