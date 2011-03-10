# Competence profile, e.g. Steel structures
class Profile < ActiveRecord::Base

  belongs_to :curriculum
  
  has_many :profile_descriptions, :dependent => :destroy
  has_many :competences, :dependent => :destroy   # e.g. levels 1, 2, 3
  
  
end
