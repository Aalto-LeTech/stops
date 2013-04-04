# Join model that connects competence profiles to prerequisite courses
class CompetenceCourse < ActiveRecord::Base
  self.table_name = 'competence_courses_cache'
  
  belongs_to :competence
  belongs_to :scoped_course
  
end
