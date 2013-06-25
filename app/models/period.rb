# Teaching period
class Period < ActiveRecord::Base

  has_many :period_descriptions, :dependent => :destroy
  
  has_one :localized_description, :class_name => "PeriodDescription", 
          :conditions => proc { "locale = '#{I18n.locale}'" }

  has_many :course_instances


  def name(locale)
    name = PeriodDescription.where(:period_id => self.id, :locale => locale.to_s).first
    name ? name.name : ''
  end
  
  def localized_name
    desc = localized_description
    desc.name
  end

  # Finds the next period following this period
  def find_next_periods(limit=1)
    Period.where(["begins_at >= ?", self.ends_at]).order("begins_at").limit(limit)
  end

  def to_roman_numeral
    num_to_roman(self.number + 1)
  end

  # Returns the ongoing period (according to Date.today)
  def self.current
    find_by_date(Date.today)
  end

  # Returns the period that was active at the given date
  def self.find_by_date(date)
    Period.where(["begins_at <= ? AND ends_at > ?", date, date]).first
  end


  private

  # Decimal to Roman numeral converter
  def num_to_roman(num)
    @@Romans = [
                ["X",   10],
                ["IX",   9],
                ["V",    5],
                ["IV",   4],
                ["I",    1]
               ]

    left = num
    romanized = []
    for roman, arabic in @@Romans 
      times, left = left.divmod(arabic)
      romanized << roman * times
    end

    romanized.join("")
  end

end
