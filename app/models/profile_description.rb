# Internationalized description of a profile
class ProfileDescription < ActiveRecord::Base
  belongs_to :profile
  
  validates_presence_of :locale
  validates_presence_of :name
  
end
