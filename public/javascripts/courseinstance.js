function CourseInstance(course, period, length) {
  this.course = course;
  this.period = period;
  this.length = length;
  
  period.addCourseInstance(this);
  course.addCourseInstance(this);
};

CourseInstance.prototype.getCourse = function() {
  return this.course;
}

CourseInstance.prototype.getPeriod = function() {
  return this.period;
}
