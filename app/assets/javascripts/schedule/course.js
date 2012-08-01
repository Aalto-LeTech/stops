function Course(element) {
  element.data('object', this);     // Add a reference from element to this
  this.element = element;           // jQuery element
  
  this.instances = {};         // Available course instances
  this.periods = [];           // Periods on which this course is arranged
  this.prereqs = {};           // Prerequisite courses. courseCode => course object
  this.prereqTo = {};          // Courses for which this course is a prereq. courseCode => course object
  this.prereqPaths = [];       // Raphael paths to prerequirement courses
  this.period = false;         // Period 
  this.courseInstance = false; // Selected courseinstance
  this.slot = false;           // Slot number that this course occupies
  this.length = 1;
  this.locked = false;         // Is the course immovable?
  this.changed = true;
  
  this.id = element.data('id');    // Database id of the UserCourse
  this.code = element.data('code');
  this.name = element.data('name');
  this.credits = element.data('credits');
  this.passed = element.data('passed') == 'true';
  
  element.click(Course.prototype.click);
  
  element.draggable({
    containment: 'parent',
    distance: 5,
    start: Course.prototype.startDrag,
    drag: Course.prototype.whileDragging,
    stop: Course.prototype.stopDrag,
    revert: "false"
  });
};

Course.prototype.getCode = function() {
  return this.code;
}

Course.prototype.getLength = function() {
  return this.length;
}

Course.prototype.getCredits = function() {
  return this.credits;
}

Course.prototype.isPassed = function() {
  return this.passed;
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
  this.courseInstance = this.instances[period.getId()];
  if (this.courseInstance) {
    this.length = this.courseInstance.length;
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
  for (var array_index in this.prereqs) {
    var other = this.prereqs[array_index];
    
    if (this.period.earlierThan(other.period)) {
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


Course.prototype.clearPrereqPaths =  function() {
  var selectedCourseElem = $("#plan .selected");
  if (selectedCourseElem.length !== 0) {
    var selectedCourse = selectedCourseElem.data('object'); 
    for (var i = 0; i < selectedCourse.prereqPaths.length; i++) {
       selectedCourse.prereqPaths[i].path.remove();
    }
  
    selectedCourse.prereqPaths = [];
  }
};

/**
 * Event listener
 */
Course.prototype.click = function() {
  var course = $(this).data('object');
  
  // Clear prerequirement graphs
  course.clearPrereqPaths();

  // Reset hilights
  $('.course').removeClass('prereq-of').removeClass('prereq-to').removeClass('selected');
  $('.period').removeClass('receiver');
   
  // Hilight selected course
  $(this).addClass('selected');

  // Show short course details on the controls pane
  var $courseDesc = $('#course-desc-block');
  $("#course-code").text(course.code); 
  $("#course-name").text(course.name);
  $("#course-points").text(course.credits);
  $courseDesc.removeClass("hidden"); // TODO animate
  
  
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


  /* Draw requirement graphs for selected course */
  var preCourse; 
  for (preCourse in course.prereqs) {
    if (!course.prereqs.hasOwnProperty(preCourse)) {
      continue;
    }
    preCourse = course.prereqs[preCourse];

    var prereqElem = $(planView.escapeSelector('course-' + preCourse.code));
  
    // TODO: heights and widths not in use
    var prereqPos = prereqElem.position();
    var prereqWidth = prereqElem.outerWidth(true); 
    var prereqHeight = prereqElem.outerHeight(false) + prereqElem.margin().top;
  
    var clickedElem = $(this);
    var clickedPos = clickedElem.position();
    var clickedWidth = clickedElem.outerWidth(true); 

    var newPath = planView.paper.path(Course.calcPathString(clickedElem, prereqElem));
    course.prereqPaths.push({ path: newPath, course: preCourse });
  }
}


/**
 * Event listener
 */
Course.prototype.startDrag = function(event, ui) {
  // Reset hilights
  $('.period').removeClass('receiver');

  // Dragging started, reset drop detection
  ui.helper.data('dropped', false);
  
  // Hilight the periods that have this course
  var $element = ui.helper;
  var periods = $element.data('object').periods;
  
  for (var array_index in periods) {
    periods[array_index].element.addClass("receiver");
  }
}


Course.prototype.whileDragging = function(event, ui) {
  // Move prerequirement graphs
  var elem = ui.helper,
      position = elem.position(),
      course = elem.data('object');

  for (var i = 0; i < course.prereqPaths.length; i++) {
    var node = course.prereqPaths[i],
        path = node.path,
        prereqCourse = node.course,
        $prereqElem = $(planView.escapeSelector('course-' + prereqCourse.code));
    path.attr({ path: Course.calcPathString(elem, $prereqElem) }); 
  }
}

Course.prototype.stopDrag = function(event, ui) {
  if (!ui.helper.data('dropped')) {
    // Animate draggable back to its original position
    ui.helper.animate(ui.originalPosition, { 
      duration: 500,
      step: function(now, fx) {
        var $courseElem = $(this),
            course = $courseElem.data('object');

        // Update graphs too
        for (var i = 0; i < course.prereqPaths.length; i++) {
          var node = course.prereqPaths[i],
              path = node.path,
              prereqCourse = node.course,
              $prereqElem = $(planView.escapeSelector('course-' + prereqCourse.code));
          path.attr({ path: Course.calcPathString($courseElem, $prereqElem) });
        }
      }
    });
  }
}


/* Class methods */

/**
 * Calculates SVG path string between course node element and a prerequirement
 * element.
 *
 * */
Course.calcPathString = function(courseNode, prereqNode) {
  var fX, fY, tX, tY, coursePos, prereqPos;
  coursePos = courseNode.position();
  prereqPos = prereqNode.position();
  fX = coursePos.left + courseNode.outerWidth(true) / 2.0;
  fY = coursePos.top;
  tX = prereqPos.left + prereqNode.outerWidth(true) / 2.0;
  tY = prereqPos.top + prereqNode.outerHeight(false) + prereqNode.margin().top;

  return "M" + fX + "," + fY + "T" + tX + "," + tY;
}

