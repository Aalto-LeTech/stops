class Curriculum < ActiveRecord::Base

  validates_presence_of :start_year
  validates_presence_of :end_year
  validates_uniqueness_of :start_year
  validates_uniqueness_of :end_year
  
  has_many :profiles, :dependent => :destroy
  has_many :courses, :dependent => :destroy

  # Returns a human-readable representation, e.g. "2010" or "2010-2011"
  def name
    return '' if self.new_record?
    
    if self.end_year > self.start_year
      return "#{self.start_year} &mdash; #{self.end_year}"
    else
      return self.start_year
    end
  end

end
