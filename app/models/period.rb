# Teaching period
class Period < ActiveRecord::Base

  has_many :period_descriptions, :dependent => :destroy
  
  has_many :course_instances
  
  def name(locale)
    name = PeriodDescription.where(:period_id => self.id, :locale => locale.to_s).first
    name ? name.name : ''
  end
  
  # Returns the ongoing period (according to Date.today)
  def self.current
    find_by_date(Date.today)
  end
  
  # Returns the period that was active at the given date
  def self.find_by_date(date)
    self.where(["begins_at <= ? AND ends_at > ?", date, date]).first
  end
  

end
