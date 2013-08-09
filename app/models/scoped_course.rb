# Course as a part of a curriculum, e.g. Programming 101 as described in the 2011 study guide
class ScopedCourse < CompetenceNode

  # members
  #  -> abstract_course
  #  -> abstract_course -> localized_description = course_descriptions (name, locale, ...) -> localized_name
  #  -> abstract_course -> periods (future)
  #  -> skill_descriptions & localized_skill_descriptions
  #  -> course_prereqs ???
  #  -> prereqs ???
  #  -> strict_prerequirement_skills ???
  #  -> prereqs ???
  #  -> strict_prereqs ???
  #  -> supporting_prereqs ???
  #  -> course_prereq_to ???
  #  -> prereq_to ???
  #  <- comments


  # Abstract course
  belongs_to :abstract_course
  accepts_nested_attributes_for :abstract_course


  # Localized descriptions
  has_many :course_descriptions, :dependent => :destroy,
          :primary_key => :abstract_course_id,
          :foreign_key => :abstract_course_id

  accepts_nested_attributes_for :course_descriptions

  has_one :localized_description, :class_name => "CourseDescription",
          :conditions => proc { "locale = '#{I18n.locale}'" },
          :primary_key => :abstract_course_id,
          :foreign_key => :abstract_course_id


  # Skills
  has_many :skill_descriptions,
           :through => :skills

  has_many :localized_skill_descriptions,
           :through     => :skills,
           :class_name  => "SkillDescription",
           :source      => :localized_description


  # Prerequisite relationships

  # Prerequisite competence nodes
  has_many :strict_prereqs,
           :through     => :strict_prerequirement_skills,
           :source      => :competence_node

  has_many :strict_prerequirement_skills,
           :through     => :skills,
           :source      => :strict_prereqs

  # Prerequisite courses
  has_many :course_prereqs,
           :dependent => :destroy

  has_many :prereqs,
           :through => :course_prereqs,
           :source  => :prereq

  has_many :supporting_prereqs,
           :through     => :course_prereqs,
           :source      => :prereq,
           :order       => 'requirement DESC, course_code',
           :conditions  => "requirement = #{SUPPORTING_PREREQ}"

  # Courses for which this is a prerequisite
  has_many :course_prereq_to,
           :class_name  => 'CoursePrereq',
           :foreign_key => :scoped_prereq_id

  has_many :prereq_to,
           :through     => :course_prereq_to,
           :source      => :course,
           :order       => 'course_code',
           :conditions  => "requirement = #{STRICT_PREREQ}"


  # Periods (yet to be ended, only)
  has_many :periods,
           :through     => :abstract_course,
           :conditions  => proc { ["periods.ends_at > ?", Date.today] }


  # Comments
  has_many :comments,
           :as => :commentable,
           :dependent => :destroy,
           :order => 'created_at'


  # In the new version of TS, the index lives in app/indices/scoped_course_index.rb
  #
  ## Define Sphinx index
  #define_index do
  #  indexes course_code
  #  indexes localized_description(:name), :as => :course_name
  #  indexes skill_descriptions.description, :as => :skill_descriptions

  #  has :id, :as => :scoped_course_id
  #  has :abstract_course_id
  #  # has skills(:id)
  #end


  # Old accessor for localized name  # FIXME: should this be removed?
  def name(locale)
    description = course_descriptions.where(:locale => locale).first
    description ? description.name : course_code
  end


  # Returns the name of the course in the current locale or fallback
  # message if localized course name could not be found.
  def name_or(fallback_message="<No name set for the locale>")
    desc = localized_description
    desc ? desc.name : fallback_message
  end


  def localized_name_exists?
    not localized_name.nil?
  end


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


  # Returns -1 if the is a prereq of other, +1 if this is a prereq to other, otherwise 0.
  def <=>(other)
    if strict_prereqs.exists?(other)
      return 1
    elsif prereq_to.exists?(other)
      return -1
    else
      return 0
    end
  end


  # Returns the unique roman numerals of the periods where this course
  # has an course instance and the period hasn't ended or started yet.
  # Example: ["I", "III", "IV"]
  def periods_as_roman_numerals
    periods_sorted = self.periods.sort! { |x, y| x.number <=> y.number }
    periods_sorted.map { |period| period.to_roman_numeral }.uniq
  end


  # Returns all courses and their prereqs, recursively
  def prereqs_recursive
    courses = Hash.new

    self.strict_prereqs.each do |prereq|
      prereq.collect_prereqs(courses)
    end

    courses.values
  end


  # Adds a course and its prereqs recursively to the given courses collection.
  # If a course belongs to a prereq cycle, it is added to the cycles collection.
  def collect_prereqs(courses)
    # Do not follow branches that have already been handled
    return if courses.has_key?(self.id)

    # Add this course to the list
    courses[self.id] = self

    # Add pereqs of this course to the list
    strict_prereqs.each do |prereq|
      prereq.collect_prereqs(courses)
    end
  end


  # Updates the prerequirement course cache.
  # The cache is a table behind the 'prereqs' variable that provides easy access to all the prerequirement courses which provide at least one competence that is a prerequirement for this course.
  def update_prereqs_cache
    self.prereqs_recursive.each do |prereq|
      CoursePrereq.create(:course => self, :prereq => prereq, :requirement => STRICT_PREREQ)
    end
  end

end
