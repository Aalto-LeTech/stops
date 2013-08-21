ScopedCourse.find_each do |scoped_course|
  scoped_course.update_prereqs_cache
end
