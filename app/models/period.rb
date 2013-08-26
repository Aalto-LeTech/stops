# Teaching period
class Period < ActiveRecord::Base

  #  create_table "periods", :force => true do |t|
  #    t.integer "number",    :null => false
  #    t.date    "begins_at"
  #    t.date    "ends_at"
  #  end

  # members
  #  <- localized_description = period_descriptions (name, locale)
  #  <- course_instances
  #  - number
  #  - begins_at
  #  - ends_at


  has_one :localized_description, :class_name => "PeriodDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" }

  has_many :course_instances


  def localized_name
    localized_description.nil? ? "" : localized_description.name
  end


  def symbol
    localized_description.nil? ? "" : localized_description.symbol
  end


  # Finds the first period in the db
  def find_first
    Period.order("begins_at ASC").first
  end


  # Finds the preceding period(s)
  def find_preceding(limit=1)
    limit == 0 ? self : Period.where(["ends_at < ?", self.begins_at]).order("begins_at DESC").limit(limit)
  end


  # Finds the following period(s)
  def find_following(limit=1)
    limit == 0 ? self : Period.where(["begins_at >= ?", self.ends_at]).order("begins_at ASC").limit(limit)
  end


  # Returns the ongoing period (according to Date.today)
  def self.current
    find_by_date(Date.today)
  end


  # Returns the period that was active at the given date
  def self.find_by_date(date)
    Period.where(["begins_at <= ? AND ends_at > ?", date, date]).first
  end


  # Returns a period range
  def self.range(first, last)
    Period.where(["begins_at >= ? AND ends_at <= ?", first.begins_at, last.ends_at]).order("begins_at")
  end

end
