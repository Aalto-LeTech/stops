# Competence profile
class Profile < ActiveRecord::Base

  # Prerequisites
  has_many :profile_courses
  has_many :courses, :through => :profile_courses, :source => :course, :order => 'code'
  
  has_many :strict_prereqs, :through => :profile_courses, :source => :course, :order => 'code', :conditions => "requirement = #{STRICT_PREREQ}"
  has_many :supporting_prereqs, :through => :profile_courses, :source => :course, :order => 'code', :conditions => "requirement = #{SUPPORTING_PREREQ}"
  
  
  def name(locale)
    description = ProfileDescription.find(:first,  :conditions => { :profile_id => self.id, :locale => locale.to_s })
    description ? description.name : ''
  end
  
end
