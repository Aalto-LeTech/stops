function Course(element) {
  element.data('object', this);     // Add a reference from the jQuery object to this
  this.element = element;           // jQuery element
  
  this.instances = {};
  this.periods = [];        // Periods on which this course is arranged
  this.prereqs = {};        // Prerequisite courses. courseCode => course object
  this.prereqTo = {};       // Courses for which this course is a prereq. courseCode => course object
  this.period = false;      // Period 
  this.slot = false;        // Slot number that this course occupies
  this.length = 1;
  
  this.code = element.data('code');
  
  element.click(Course.prototype.click);
  
  element.draggable({
    containment: 'parent',
    distance: 5,
    start: Course.prototype.startDrag
  });
};

Course.prototype.getCode = function() {
  return this.code;
}

Course.prototype.getLength = function() {
  return this.length;
}

Course.prototype.setSlot = function(slot) {
  this.slot = slot;
  this.element.css('left', slot * 100);
}

Course.prototype.getSlot = function() {
  return this.slot;
}

Course.prototype.getPrereqs = function() {
  return this.prereqs;
}

/**
 * Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
 */
Course.prototype.addPrereq = function(other) {
  this.prereqs[other.code] = other;
  other.prereqTo[this.code] = this;
}

/**
 * Adds an instance of this course to the given period. 
 */
Course.prototype.addCourseInstance = function(courseInstance) {
  var period = courseInstance.getPeriod();
  this.instances[period.getId()] = courseInstance;
  this.periods.push(period);
}

/**
 * Moves this course to the given period
 */
Course.prototype.setPeriod = function(period) {
  // Remove course from previous period. Note: length must not be updated before freeing the old slots.
  if (this.period) {
    this.period.removeCourse(this);
  }
  
  // Update length
  var courseInstance = this.instances[period.getId()];
  if (courseInstance) {
    this.length = courseInstance.length;
  } else {
    this.length = 1;
  }
  
  // Add course to the new period
  this.period = period;
  period.addCourse(this, false);
  
  // Move the div
  var period_div_pos = period.element.position();
  //course.css('left', period_div_pos.left + freeSlot * 100);
  this.element.css('top', period_div_pos.top + 2);
  this.element.css('height', this.length * 50 - 6);
}

Course.prototype.getPeriod = function(period) {
  return this.period;
}

/**
 * Moves all prereqs before this course.
 */
Course.prototype.satisfyPrereqs = function() {
  // Quit recursion if this course is part of an unsolvable chain
  if (!this.period) {
    return;
  }
  
  // Move prereqs before this course
  for (var array_index in this.prereq) {
    var other = this.prereq[array_index];
    
    if (this.period.eralierThan(other.period)) {
      other.advanceTo(this.period.getPreviousPeriod());
      other.satisfyPrereqs();
    }
  }
}

/**
 * Moves forward all courses that require this course
 */
Course.prototype.satisfyPostreqs = function() {
  // Quit recursion if this course is part of an unsolvable chain
  if (!this.period) {
    return;
  }
  
  // Postpone postreqs that are earlier than this
  for (var array_index in this.prereqTo) {
    var other = this.prereqTo[array_index];
    
    if (this.period.laterOrEqual(other.period)) {
      other.postponeTo(this.period.getNextPeriod());
      other.satisfyPostreqs();
    }
  }
}

/**
 * Moves this course to the first available period starting from the given period.
 */
Course.prototype.postponeTo = function(period) {
  while (period) {
    if (period.courseAvailable(this)) {
      //this.period = period;
      this.setPeriod(period);
      return;
    }

    period = period.getNextPeriod();
  }
  
  // No period could be found.
  this.period = false;
}

/**
 * Moves this to the given period or the closest possible earlier period
 */
Course.prototype.advanceTo = function(period) {
  while (period) {
    if (period.courseAvailable(this)) {
      //this.period = period;
      this.setPeriod(period);
      return;
    }

    period = period.getPreviousPeriod();
  }
  
  // No period could be found.
  this.period = false;
}

/**
 * Moves the course forward after its prereqs (those that have been located on a period).
 * If no prereqs are found, course remains on the current period.
 */
Course.prototype.postponeAfterPrereqs = function() {
  // Find the latest of the prereqs
  var latest = false;
  for (var array_index in this.prereqs) {
    var course = this.prereqs[array_index];
    var period = course.getPeriod();
    
    if (period && (!latest || course.getPeriod().laterThan(latest.getPeriod()))) {
      latest = course;
    }
  }
  
  if (latest) {
    this.postponeTo(latest.getPeriod().getNextPeriod());
  }
}

/**
 * Event listener
 */
Course.prototype.click = function() {
  var course = $(this).data('object');
  
  // Reset hilights
  $('.course').removeClass('prereq-of').removeClass('prereq-to').removeClass('selected');
  $('.period').removeClass('receiver');
  
  // Hilight selected course
  $(this).addClass('selected');
  
  // Hilight prereqs
  for (var array_index in course.prereqs) {
    course.prereqs[array_index].element.addClass('prereq-of');
  }
  
  // Hilight courses for which this is a prereq
  for (var array_index in course.prereqTo) {
    course.prereqTo[array_index].element.addClass('prereq-to');
  }
  
  // Hilight the periods that have this course
  for (var array_index in course.periods) {
    course.periods[array_index].element.addClass("receiver");
  }
}

/**
 * Event listener
 */
Course.prototype.startDrag = function(event, ui) {
  // Reset hilights
  $('.period').removeClass('receiver');
  
  // Hilight the periods that have this course
  var $element = ui.helper;
  var periods = $element.data('object').periods;
  
  for (var array_index in periods) {
    periods[array_index].element.addClass("receiver");
  }
}