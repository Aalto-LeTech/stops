# Competence profile
class Profile < ActiveRecord::Base

  has_many :profile_descriptions, :dependent => :destroy
  
  # Prerequisite courses
  has_many :profile_courses, :dependent => :destroy
  has_many :courses, :through => :profile_courses, :source => :course, :order => 'code'
  
  has_many :strict_prereqs, :through => :profile_courses, :source => :course, :order => 'code', :conditions => "requirement = #{STRICT_PREREQ}"
  has_many :supporting_prereqs, :through => :profile_courses, :source => :course, :order => 'code', :conditions => "requirement = #{SUPPORTING_PREREQ}"
  
  # Skills provided by this profile
  # In practice, one skill belongs to only one profile. However, a join table is needed because skills can also belong to courses.
  has_and_belongs_to_many :skills
  
  
  def name(locale)
    description = ProfileDescription.find(:first,  :conditions => { :profile_id => self.id, :locale => locale.to_s })
    description ? description.name : ''
  end
  
end
