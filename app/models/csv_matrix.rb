class CsvMatrix
    # Searches for AbstractCourse with 'name'. Creates a new one if none is found.
  # Returns an AbstactCourse
  def insert_or_update_abstract_course(code, name, locale, period)
    # Insert or update course
    course = AbstractCourse.where(['LOWER(code) = ?', code.downcase]).first
    unless course
      # Create new course
      course = AbstractCourse.create(:code => code)
      description = CourseDescription.create(:abstract_course_id => course.id, :locale => locale, :name => name)
      create_course_instances(course,period)
    end
    
    return course
  end
  
  
  # Searches for a ScopedCourse associated with the given AbstractCourse and Curriculum. Creates a new one if none is found.
  # Returns a ScopedCourse
  def insert_or_update_scoped_course(abstract_course, curriculum, credits, period)
    # Insert or update course
    course = ScopedCourse.where(:abstract_course_id => abstract_course.id, :curriculum_id => curriculum.id).first
    if course
      # Update existing course
      course.credits = credits
      course.save
    else
      # Create new course
      course = ScopedCourse.create(:abstract_course_id => abstract_course.id, :curriculum_id => curriculum.id, :code => abstract_course.code, :credits => credits.gsub(',','.').to_f, :length => parse_length(period))
    end
    
    return course
  end
  
  
  def create_course_instances(abstract_course,period)
    arranged_on = []  # Periods on which the course is arranged
    
    # Parse period
    if period.blank?
      # Random pariod and length
      p = rand(4)           # Random period
      p += 1 if p > 1       # Don't put anything on the summer
      arranged_on << p

      length = 1            # Default length is 1
      if p == 0 || p == 3   # Length can be 2 if course starts on periods 0 (january) or 3 (september)
         length += rand(2)
      end
    else
      period_numbers = [2,3,4,0,1,2]    # Map internal period numbers to institution specific period numbers
      period_begin = period[0,1].to_i
      
      arranged_on << period_numbers[period_begin]
      length = parse_length(period)
    end
    
    # Create instances
    periods = Period.all
    periods.each do |period|
      # If course is arranged on this period, create instance
      if arranged_on.include? period.number
        course_instance = CourseInstance.create(:abstract_course_id => abstract_course.id, :period_id => period.id)
      end
    end
  end
  
  # Parses course length. e.g. "2-3" => 2
  # Returns integer length
  def parse_length(raw_period)
    return 1 if raw_period.blank?
    
    period_begin = raw_period[0,1].to_i
    if raw_period.size >= 3
      period_end = raw_period[2,3].to_i
    else
      period_end = period_begin       # Assume length = 1 if end is omitted
    end
    
    return period_end - period_begin + 1
  end

end