(function() {

function Period(element) {
  element.data('object', this);     // Add a reference from element to this
  this.element          = element;  // Add a reference from this to element
  
  this.credits_element  = this.element.find('.period-credits');
  
  this.courses          = {};       // Courses that have been put to this period
  this.courseInstances  = {};       // Courses that are available on this period. courseCode => courseInstance
  this.slots            = [];       // Slots for parallel courses
  
  this.previousPeriod   = false;    // Reference to previous sibling
  this.nextPeriod       = false;    // Reference to next sibling
  this.sequenceNumber;              // Sequence number to allow easy comparison of periods
  this.isCurrentPeriod  = element.data("current-period") === true;
  if (this.isCurrentPeriod) this.currentPeriod = this;
  
  this.id = element.data('id');     // Database id of this period
  
  element.droppable({
    drop: courseDropped,
    accept: isCourseAccepted 
  });
};

// Expose Period outside current scope
window.Period = Period;

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
Period.prototype.setPreviousPeriod = function(previousPeriod) {
  this.previousPeriod = previousPeriod;
  
  if (previousPeriod) {
    previousPeriod.nextPeriod = this;

    if (this.isCurrentPeriod) {
      /* Propagate current period to previous periods */
      var period = previousPeriod;
      while (period) {
        period.currentPeriod = this;
        period = period.getPreviousPeriod();
      }
    } else if (previousPeriod.currentPeriod) {
      /* Propagate current period to next periods */
      this.currentPeriod = previousPeriod.currentPeriod;
    }
  }
}

Period.prototype.getPreviousPeriod = function() {
  return this.previousPeriod;
}

Period.prototype.getPreviousPeriodUntilCurrent = function() {
  if (this.previousPeriod.laterOrEqual(this.currentPeriod))
    return this.previousPeriod;
  else
    return null;
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

Period.prototype.getCurrentPeriod = function() {
  return this.currentPeriod;
}

/**
 * Adds a course to the list of courses that are arranged on this period.
 */
Period.prototype.addCourseInstance = function(courseInstance) {
  this.courseInstances[courseInstance.getCourse().getCode()] = courseInstance;
}

/**
 * Puts a course on this period.
 */
Period.prototype.addCourse = function(course, slot) {
  this.courses[course.getCode()] = course;
  
  var length = course.getLength();  // Length in periods
  
  // Check that the slot is free. Find a free slot if it's occupied.
  if (!slot || !this.isSlotFree(slot, length)) {
    slot = this.findFreeSlot(length);
  }
  
  // Occupy slots
  this.occupySlot(slot, length, course);
  course.setSlot(slot);
  
  // Update credits
  this.updateCredits();
}

Period.prototype.updateCredits = function() {
  var credits = 0;
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    
    credits += course.getCredits();
  }
  
  this.credits_element.html(credits);
}

Period.prototype.removeCourse = function(course) {
  // Remove course from the list
  delete this.courses[course.getCode()];
  
  // Free slots
  this.freeSlot(course.getSlot(), course.getLength());
  
  // Update credits
  this.updateCredits();
}

/**
 * Returns true if the given course has an instance available on this period.
 */
Period.prototype.courseAvailable = function(course) {
  if (this.courseInstances[course.getCode()]) {
    return true;
  } else {
    return false;
  }
}

Period.prototype.findFreeSlot = function(length) {
  for(var slot = 0; slot < 100; slot++) {
    if (this.isSlotFree(slot, length)) {
      return slot;
    }
  }
}

/**
 * Returns true if the given slot is free on this and the given number of succeeding periods.
 */
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
 * @param course Course that occupies the slot.
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


/**
 *  Decides whether droppable should accept given draggable.
 */
function isCourseAccepted(draggable) {
  var course = draggable.data('object');   
  var period = $(this).data('object');
  if (period.laterOrEqual(planView.currentPeriod) && period.courseAvailable(course)) {
    return true;
  } else return false; 
}


/**
 * Handles course drop events.
 */
 function courseDropped(event, ui) {
  var period = $(this).data('object');
  var course = ui.draggable.data('object');

  // Draggable needs to know that drop succeeded
  ui.draggable.data('dropped', true);
  
  // Find the course instance
  course.setPeriod(period);
  if (period.courseInstances[course.getCode()]) {
    course.element.removeClass('noinstance');
  } else {
    // If there is no instance on that period, show warning
    course.element.addClass('noinstance');
  }
  
  if (planView.settings.satisfyReqsAutomatically) {
    // Move prereqs before the course
    course.satisfyPrereqs();
    
    // Move postreqs after the course
    course.satisfyPostreqs();
  }
}

})();