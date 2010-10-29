function Period(element) {
  element.data('object', this);
  this.element = element;
  
  this.courses = {};               // Courses that have been put to this period
  this.courseInstances = {};       // Courses that are available on this period. courseCode => courseInstance
  this.slots = [];
  
  this.previousPeriod = false;
  this.nextPeriod = false;
  this.sequenceNumber;             // Sequence number to allow easy comparison of periods
  
  this.id = element.data('id');
  
  element.droppable({
    drop: Period.prototype.dropCourse
  });
};

Period.prototype.getId = function() {
  return this.id;
}

Period.prototype.setSequenceNumber = function(number) {
  this.sequenceNumber = number;
}

Period.prototype.earlierThan = function(other) {
  return this.sequenceNumber < other.sequenceNumber;
}

Period.prototype.earlierOrEqual = function(other) {
  return this.sequenceNumber <= other.sequenceNumber;
}

Period.prototype.laterThan = function(other) {
  return this.sequenceNumber > other.sequenceNumber;
}

Period.prototype.laterOrEqual = function(other) {
  return this.sequenceNumber >= other.sequenceNumber;
}

/**
 * Sets the link from this period to the previous. This period is automatically added as the successor to the previous period.
 */
Period.prototype.setPreviousPeriod = function(period) {
  this.previousPeriod = period;
  
  if (period) {
    period.nextPeriod = this;
  }
}

Period.prototype.getPreviousPeriod = function() {
  return this.previousPeriod;
}

/**
 * Sets the link from this period to the next. This period is automatically added as the predecessor to the next period.
 */
Period.prototype.setNextPeriod = function(period) {
  this.nextPeriod = period;
  
  if (period) {
    period.previousPeriod = this;
  }
}

Period.prototype.getNextPeriod = function() {
  return this.nextPeriod;
}

Period.prototype.addCourse = function(course, slot) {
  this.courses[course.getCode()] = course;
  
  var length = course.getLength();
  
  // Check that the slot is free. Find a free slot if it's occupied.
  if (!slot || !this.isSlotFree(slot, length)) {
    slot = this.findFreeSlot(length);
  }
  
  // Occupy slots
  this.occupySlot(slot, length, course);
  course.setSlot(slot);
}

Period.prototype.removeCourse = function(course) {
  // Remove course from the list
  delete this.courses[course.getCode()];
  
  // Free slots
  this.freeSlot(course.getSlot(), course.getLength());
}

Period.prototype.courseAvailable = function(course) {
  
  if (this.courseInstances[course.getCode()]) {
    return true;
  } else {
    return false;
  }
  
  //return !(this.courseInstances[course.getCode()] == false);
}

Period.prototype.findFreeSlot = function(length) {
  for(var slot = 0; slot < 100; slot++) {
    if (this.isSlotFree(slot, length)) {
      return slot;
    }
  }
}

Period.prototype.isSlotFree = function(slot, length) {
  if (this.slots[slot]) {
    return false;
  }
  
  if (!this.nextPeriod || length <= 1) {
    return true;
  } else {
    return this.nextPeriod.isSlotFree(slot, length - 1);
  }
}


/**
 * Occupies slots in this and succeeding periods.
 * @param slot The slot to be freed.
 * @param length How many periods to span
 * @param course Course that occupios the slot.
 */
Period.prototype.occupySlot = function(slot, length, course) {
  this.slots[slot] = course;
  
  if (length <= 1 || !this.nextPeriod) {
    return;
  }
  
  this.nextPeriod.occupySlot(slot, length - 1, course);
}

/**
 * Frees slots in this and succeeding periods.
 * @param slot The slot to be freed.
 * @param length How many periods to span
 */
Period.prototype.freeSlot = function(slot, length) {
  this.slots[slot] = false;
  
  if (length <= 1 || !this.nextPeriod) {
    return;
  }
  
  this.nextPeriod.freeSlot(slot, length - 1);
}

Period.prototype.autoplan = function() {

}

/**
 * Adds a course to the list of courses that are arranged on this period.
 */
Period.prototype.addCourseInstance = function(courseInstance) {
  this.courseInstances[courseInstance.getCourse().getCode()] = courseInstance;
}

Period.prototype.dropCourse = function(event, ui) {
  var period = $(this).data('object');
  var course = ui.draggable.data('object');
  
  // Reset all hilights
  $('.period').removeClass('receiver');
  
  // Find the course instance
  course.setPeriod(period);
  if (period.courseInstances[course.getCode()]) {
  } else {
    alert("No instance"); // If there is no instance on that period, show warning
  }
  
  course.satisfyPrereqs();
  course.satisfyPostreqs();

}
