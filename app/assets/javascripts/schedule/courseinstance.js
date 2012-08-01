function CourseInstance(course, period, length, id) {
  this.course = course;
  this.period = period;
  this.length = length;
  this.id = id;
};

CourseInstance.prototype.getId = function() {
  return this.id;
}

CourseInstance.prototype.getCourse = function() {
  return this.course;
}

CourseInstance.prototype.getPeriod = function() {
  return this.period;
}
