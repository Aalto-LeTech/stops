# Course as a part of a curriculum, e.g. Programming 101 as described in the 2011 study guide
class ScopedCourse < CompetenceNode

  # Abstract course
  belongs_to :abstract_course

  # Localized descriptions
  has_many :course_descriptions,
          :primary_key => :abstract_course_id,
          :foreign_key => :abstract_course_id,
          :order => 'locale'

  has_one :localized_description, :class_name => "CourseDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" },
          :primary_key => :abstract_course_id,
          :foreign_key => :abstract_course_id

  # Periods (yet to be ended, only)
  has_many :periods,
           :through     => :abstract_course,
           :conditions  => proc { ["periods.ends_at > ?", Date.today] }

  # Comments
  has_many :comments,
           :as => :commentable,
           :dependent => :destroy,
           :order => 'created_at'


  def localized_name
    desc = localized_description
    (desc && desc.name != "" ) ? desc.name : nil
  end


  def localized_name_if_possible(fallback='')
    name = localized_name
    if not name
      descriptions = course_descriptions
      locale_to_desc = descriptions.inject({}) do |hash, desc|
        hash[desc.locale] = desc
        hash
      end

      # Try the locales in prioritized order
      ['en', 'fi', 'sv'].each do |locale|
        if locale_to_desc[locale] && locale_to_desc[locale].name != ''
          name = locale_to_desc[locale].name
          break
        end
      end

      name = fallback if name.nil?
    end

    name
  end


  def update_comments(hash)
    write_attribute(:comments, hash.to_json)
  end


  def comment(field)
    @comments = JSON.parse(read_attribute(:comments) || '{}') unless defined?(@comments)

    @comments[field]
  end

  # Returns the unique roman numerals of the periods where this course
  # has an course instance and the period hasn't ended or started yet.
  # Example: ["I", "III", "IV"]
  def period_symbols
    periods_sorted = self.periods.sort! { |x, y| x.number <=> y.number }
    periods_sorted.map { |period| period.symbol }.uniq
  end

  # Returns -1 if the is a prereq of other, +1 if this is a prereq to other, otherwise 0.
#   def <=>(other)
#     if strict_prereqs.exists?(other)
#       return 1
#     elsif prereq_to.exists?(other)
#       return -1
#     else
#       return 0
#     end
#   end

end
