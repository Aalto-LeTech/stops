

# lists all
#   scoped courses
#     with their abstract course code
#     and their prereq course names
#


ScopedCourse.all.each do |scoped_course|
  puts "Scoped: #{scoped_course.localized_description.name}"
  if scoped_course.abstract_course
    puts "Abstract: #{scoped_course.abstract_course.code}"
  else
    puts "Abstract: NULL"
  end
  if scoped_course.prereqs.size > 0
    puts "Prereqs:"
    scoped_course.prereqs.each do |prereq_course|
      puts " - #{prereq_course.localized_description.name}"
    end
  else
    puts "Prereqs: NONE"
  end
  puts "\n\n"
end




