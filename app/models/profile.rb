# Competence profile, e.g. Steel structures
class Profile < ActiveRecord::Base

  belongs_to :curriculum
  
  has_many :profile_descriptions, :dependent => :destroy
  has_many :competences, :dependent => :destroy   # e.g. levels 1, 2, 3
  
  accepts_nested_attributes_for :profile_descriptions
  
  def name(locale)
    description = ProfileDescription.where(:profile_id => self.id, :locale => locale.to_s).first
    description ? description.name : ''
  end
  
  def description(locale)
    description = ProfileDescription.where(:profile_id => self.id, :locale => locale.to_s).first
    description ? description.description : ''
  end

end
