

ScopedCourse.all.each do |scoped_course|
  scoped_course.update_course_prereqs_cache
end


