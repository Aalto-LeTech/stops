

ScopedCourse.all.each do |scoped_course|
  scoped_course.update_course_prereqs_cache
end


#CoursePrereq.all.each do |course_prereqs_cache|
#  course_prereqs_cache.requirement = 1
#  course_prereqs_cache.save
#  y course_prereqs_cache
#end


