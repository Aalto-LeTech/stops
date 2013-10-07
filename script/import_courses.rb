def import_courses(filename)
  STDERR.puts filename
  # period_regexp = Regexp.new('([IV]{1,3})')
  
  File.open(filename, 'r') do |input|
    line_counter = 0
    input.each_line do |line|
      line_counter += 1
      parts = line.split(';')

      #puts "#{parts[0].strip}:#{parts[5].strip}"
      #next
      
      raise "Invalid data on line #{line_counter}" if parts.size != 12
      course_code = parts[0].strip
      course_name = parts[1].strip
      noppa_url = parts[2].gsub('noppa-api-dev', 'noppa')
      oodi_url = parts[3]
      
      credits = parts[4]
      credits_parts = credits.split('-')
      min_credits = credits_parts[0].to_i
      max_credits = credits_parts.size > 1 ? credits_parts[1].to_i : credits_parts[0].to_i
      
      period = parts[5].gsub(/<[^<>]*>/, '').strip
      prereqs = parts[6]
      grading = parts[7]
      language = parts[8]
      learning_outcomes = parts[9]
      content = parts[10]
      substitutes = parts[11]
      
      abstract_course = AbstractCourse.find_by_code(course_code)
      unless abstract_course
        STDERR.puts "#{course_code}: CREATING"
        abstract_course = AbstractCourse.new(:code => course_code)
      else
        STDERR.puts "#{course_code}: found"
      end
      
      if abstract_course.min_credits != min_credits || abstract_course.max_credits != max_credits
        abstract_course.min_credits = min_credits
        abstract_course.max_credits = max_credits
        abstract_course.save
      end
      
      description_fi = CourseDescription.find_by_abstract_course_id(abstract_course.id) || CourseDescription.new(
            :abstract_course_id => abstract_course.id,
            :locale => 'fi',
            :name => course_name,
            )
      
      description_fi.noppa_url = noppa_url
      description_fi.oodi_url = oodi_url
      description_fi.period_info = period
      description_fi.prerequisites = prereqs #if description_fi.prerequisites.blank?
      description_fi.outcomes = learning_outcomes #if description_fi.outcomes.blank?
      description_fi.replaces = substitutes #if description_fi.replaces.blank?
      description_fi.content = content #if description_fi.content.blank?
      
      description_fi.save
    end
    
    STDERR.puts
  end
  
end

filename = ARGV[0]
if filename
  import_courses(filename)
else
  STDERR.puts "usage: import_courses filename"
end
