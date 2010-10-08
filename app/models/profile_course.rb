# Join model that connects competence profiles to prerequisite courses
class ProfileCourse < ActiveRecord::Base

  belongs_to :profile
  belongs_to :scoped_course
  
end
