function PathCourse(code) {
  this.code = code;
  this.prereqs = {};           // Prerequisite courses. courseCode => course object
  this.prereqTo = {};          // Courses for which this course is a prereq. courseCode => course object

  this.x = 0;
  this.y = 0;
  
};


PathCourse.prototype.getPrereqs = function() {
  return this.prereqs;
}

/**
 * Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
 */
PathCourse.prototype.addPrereq = function(other) {
  this.prereqs[other.code] = other;
  other.prereqTo[this.code] = this;
}
