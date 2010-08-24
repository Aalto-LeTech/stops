# Competence profile
class Profile < ActiveRecord::Base

  # Prerequisites
  has_many :profile_courses
  has_many :courses, :through => :profile_courses, :source => :course, :order => 'code'
  
  
  def name(locale)
    description = ProfileDescription.find(:first,  :conditions => { :profile_id => self.id, :locale => locale.to_s })
    description ? description.name : ''
  end
  
end
