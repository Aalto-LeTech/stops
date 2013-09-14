def import_courses(filename)
  puts filename
  # period_regexp = Regexp.new('([IV]{1,3})')
  
  File.open(filename, 'r') do |input|
    line_counter = 0
    input.each_line do |line|
      line_counter += 1
      parts = line.split(';')
      raise "Invalid data on line #{line_counter}" if parts.size != 9

      course_code = parts[0].strip
      course_name = parts[1].strip
      noppa_url = parts[2].gsub('noppa-api-dev', 'noppa')
      oodi_url = parts[3]
      
      credits = parts[4]
      credits_parts = credits.split('-')
      min_credits = credits_parts[0].to_i
      max_credits = credits_parts.size > 1 ? credits_parts[1].to_i : credits_parts[0].to_i
      
      period = parts[5].gsub(/<[^<>]*>/, '').strip #.gsub(/<(\/)?p>/, '')
      prereqs = parts[6]
      grading = parts[7]
      language = parts[8]
      
      abstract_course = AbstractCourse.find_by_code(course_code)
      unless abstract_course
        STDERR.puts "#{course_code}: CREATING"
        abstract_course = AbstractCourse.create(:code => course_code)
      else
        STDERR.puts "#{course_code}: found"
      end
      
      description_fi = CourseDescription.find_by_abstract_course_id(abstract_course.id) || CourseDescription.new(
            :abstract_course_id => abstract_course.id,
            :locale => 'fi',
            :name => course_name,
            )
      
      description_fi.noppa_url = noppa_url
      description_fi.oodi_url = oodi_url
      description_fi.period_info = period
      
      description_fi.save
    end
  end
  
end

import_courses('data/courses-chem.txt')
import_courses('data/courses-econ.txt')
import_courses('data/courses-elec.txt')
import_courses('data/courses-eng.txt')
import_courses('data/courses-sci.txt')
