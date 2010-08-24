# part of profiles
class Area < ActiveRecord::Base

  def name(locale)
    description = AreaDescription.find(:first, :conditions => { :area_id => self.id, :locale => locale.to_s })
    description ? description.name : ''
  end
  
  def description(locale)
    description = AreaDescription.find(:first, :conditions => { :area_id => self.id, :locale => locale.to_s })
    description ? description.description : ''
  end
  
end
