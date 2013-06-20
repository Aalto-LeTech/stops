var Course = (function() {

function Course(element) {
  element.data('object', this);     // Add a reference from element to this
  this.element = element;           // jQuery element

  this.instances      = {};         // Available course instances
  this.periods        = [];         // Periods on which this course is arranged
  this.prereqs        = {};         // Prerequisite courses. courseCode => course object
  this.prereqTo       = {};         // Courses for which this course is a prereq. courseCode => course object
  this.prereqPaths    = [];         // Raphael paths to prerequirement courses
  this.period         = false;      // Period 
  this.courseInstance = false;      // Selected courseinstance
  this.slot           = false;      // Slot number that this course occupies
  this.length         = 1;
  this.locked         = false;      // Is the course immovable?
  this.unschedulable          = false;      // true if period allocation algorithm cannot find suitable period
  this.prereqsUnsatisfiableIn = {};         /* Set of periods where prereqs of the course cannot be satisfied. From period.id => period */
  this.changed        = true;

  this.id           = element.data('id');    // Database id of the UserCourse
  this.course_code  = element.data('code');
  this.name         = element.data('name');
  this.credits      = parseFloat(element.data('credits'));
  this.passed       = element.data('passed') == 'true';

  element.click(courseClicked);

  element.draggable({
    containment: 'parent',
    distance:     5,
    start:        courseDragStarted,
    drag:         courseBeingDragged,
    stop:         courseDragStopped,
    revert:       "false"
  });

  /* Click handler registration must come after initializing draggable or otherwise 
   * clicks will not be prevented correctly after drags. */
  element.click(courseClicked);
}

Course.prototype.getCode = function() {
  return this.course_code;
};

Course.prototype.getLength = function() {
  return this.length;
};

Course.prototype.getCredits = function() {
  return this.credits;
};

Course.prototype.isPassed = function() {
  return this.passed;
};

Course.prototype.setSlot = function(slot) {
  this.slot = slot;
  this.element.css('left', slot * 115);
};

Course.prototype.getSlot = function() {
  return this.slot;
};

Course.prototype.getPrereqs = function() {
  return this.prereqs;
};

/**
 * Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
 */
Course.prototype.addPrereq = function(other) {
  this.prereqs[other.course_code] = other;
  other.prereqTo[this.course_code] = this;
};

/**
 * Adds an instance of this course to the given period. 
 */
Course.prototype.addCourseInstance = function(courseInstance) {
  var period = courseInstance.getPeriod();
  this.instances[period.getId()] = courseInstance;
  this.periods.push(period);
};

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
  this.element.css('top', period_div_pos.top + 3);
  this.element.css('height', this.length * 42 + (this.length - 1) * 15);
  this.element.removeClass("hide");

  console.log("setPeriod: called on course: " + this.code + " " + this.name);

  /* Update possible prerequirement graph paths of the current course
   * and any of the paths of its postrequirement courses. */
  this.updatePrereqPaths();
  $.each(this.prereqTo, function(key, postReqCourse) {
    postReqCourse.updatePrereqPaths();
  });
};


Course.prototype.clearPeriodAndHide = function() {
  if (this.period) {
    this.period.removeCourse(this);
  }
  this.period = false;

  this.clearPrereqPaths();
  this.element.addClass("hide");
};

/* Mark the course as unschedulable by the automatic scheduling algorithm
 * (i.e., there were no available periods with course instances late enough
 * to satisfy prerequirements). */
Course.prototype.markUnschedulable = function() {
  if (!this.locked) {
    /* Remove period */
    if (this.period) {
      this.period.removeCourse(this);
      this.courseInstance = false;
      this.period = false;
    }

    this.unschedulable = true;

    console.log("markUnschedulable: Marked unschedulable course " + this.code + " " + this.name);

    /* Remove course element from view */
    this.element.addClass("hide");
  }
};

Course.prototype.getPeriod = function(period) {
  return this.period;
};

Course.prototype.checkPrereqSatisfiabilityInPeriod = function(period) {
  var positions = {},               // Simulated current periods of courses
      coursesToBeChecked = [this];

  // The course must be in the period that we want to check
  positions[this.id] = period;

  function _getPeriodOfCourse(course) {
    if (course.id in positions)
      return positions[course.id];
    else {
      positions[course.id] = course.period;
      return course.period;
    }
  }

  /* Simulate satisfyPrereqs() */
  while (coursesToBeChecked.length != 0) {
    var course = coursesToBeChecked.pop(),
        prereq_code,
        periodOfCourse = _getPeriodOfCourse(course);

    console.log("POP: Popped " + course.code + " " + course.name + " from stack");

    if (!periodOfCourse) {
      /* Prereqs cannot be satisfied */
      this.prereqsUnsatisfiableIn[period.id] = period;
      return;
    }

    for (prereq_code in this.prereqs) {
      /* Get current simulated period values */
      var prereq         = this.prereqs[prereq_code],
          periodOfPrereq = _getPeriodOfCourse(prereq);

      console.log("PREREQ: Handling prereq course " + prereq.code + " " + prereq.name);

      if (periodOfCourse.earlierThan(periodOfPrereq)) {
        /* advanceTo(period) simulation */
        var targetPeriod = periodOfCourse.getPreviousPeriod();
        while (targetPeriod) {
          if (targetPeriod.courseAvailable(course)) {
            break;
          }

          targetPeriod = targetPeriod.getPreviousPeriod();
        }

        positions[prereq.id] = targetPeriod;
        if (!targetPeriod) console.log("PREREQ COURSE UNSCHEDULABLE: No target period could be found!");

        coursesToBeChecked.push(prereq);
        console.log("PUSH: Pushed " + prereq.code + " " + prereq.name + " into stack");
      }
    }
  }

};

Course.prototype.checkPrereqSatisfiability = function() {
  var course = this;
  $.each(this.periods, function(i, period) {
    if (period.earlierThan(course.period)) {
      course.checkPrereqSatisfiabilityInPeriod(period);
    }
  });
};

Course.prototype.isSchedulableInPeriod = function(period) {
  if (period.id in this.prereqsUnsatisfiableIn)
    return false;
  else
    return true;
};

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
      other.advanceTo(this.period.getPreviousPeriodUntilCurrent());
      other.satisfyPrereqs();
    }
  }
};

/**
 * Moves forward all courses that require this course
 */
Course.prototype.satisfyPostreqs = function() {
  // Quit recursion if this course is part of an unsolvable chain
  if (!this.period) {
    /* Mark the rest of the postrequirements as unschedulable since we weren't
     * able to schedule the current course. */
    this.markPostreqsUnschedulable();
    return;
  }

  /* Determine to which period postrerequirements should be postponed */
  var targetPeriod;
  if (this.locked) {
    /* Since the current course is locked, the course might be before
     * its prerequirements, so we need to find out the latest period of
     * the set of the current course and its prerequirements. */
    var latest = this.getPeriod();
    for (var array_index in this.prereqs) {
      var course = this.prereqs[array_index];
      var period = course.getPeriod();
      
      if (period && (!latest || period.laterThan(latest))) {
        latest = period;
      }
    }

    targetPeriod = latest.getNextPeriod();
  } else {
    /* Move postrequirements right after the current course */
    targetPeriod = this.getPeriod().getNextPeriod();
  }
  
  // Postpone postreqs that are earlier than this
  for (var array_index in this.prereqTo) {
    var other = this.prereqTo[array_index];
    
    if (!targetPeriod || this.period.laterOrEqual(other.period)) {
      if (!other.locked) other.postponeTo(targetPeriod);
      other.satisfyPostreqs();
    }
  }
};

/**
 * Moves this course to the first available period starting from the given period.
 */
Course.prototype.postponeTo = function(period) {

  this.setPeriod(period);

  if (!this.unschedulable) {
    while (period) {
      if (period.courseAvailable(this)) {
        this.setPeriod(period);
        return;
      }

      period = period.getNextPeriod();
    }
    
    // No period could be found.
    this.markPostreqsUnschedulable(); /* Also marks period as false */
    console.log("Unschedulable: " + this.code + " " + this.name + ": Could not postpone to wanted period!");
  }

};

/**
 * Moves this to the given period or the closest possible earlier period
 */
Course.prototype.advanceTo = function(period) {
  while (period) {
    if (period.courseAvailable(this)) {
      this.setPeriod(period);
      return;
    }

    period = period.getPreviousPeriodUntilCurrent();
  }

  // No period could be found.
  this.clearPeriodAndHide();
};

/**
 * Moves the course forward after its prereqs (those that have been located on a period).
 * If no prereqs are found, course remains on the current period.
 */
Course.prototype.postponeAfterPrereqs = function() {
  // Only move if the course has not been locked into its current period
  if (!this.locked) {
    // Find the latest of the prereqs
    var latest = false;
    for (var array_index in this.prereqs) {
      var course = this.prereqs[array_index];
      var period = course.getPeriod();
      
      if (period && (!latest || period.laterThan(latest))) {
        latest = period;
      }
    }
    
    if (latest) {
      var targetPeriod  = latest.getNextPeriod(),
          currentPeriod = latest.getCurrentPeriod();
      if (targetPeriod && targetPeriod.earlierOrEqual(currentPeriod)) {
        /* We must make sure that courses are scheduled only after the current ongoing
         * period! */
        targetPeriod = currentPeriod.getNextPeriod();
      }
      this.postponeTo(targetPeriod);
    }
  }
};

/* Mark all (except locked courses) postrequirements and their
 * postrequirements as unschedulable. */
Course.prototype.markPostreqsUnschedulable = function() {
  var to_be_processed = $.map(this.prereqTo, function(course) {
    return course;
  });
  
  while(to_be_processed.length > 0) {
    var postreq = to_be_processed.pop();
    postreq.markUnschedulable();
    $.each(postreq.prereqTo, function(key, course) {
      to_be_processed.push(course);
    });
  }
};


Course.prototype.drawPrereqPaths = function() {
  var preCourse; 
  for (preCourse in this.prereqs) {
    if (!this.prereqs.hasOwnProperty(preCourse)) {
      continue;
    }
    preCourse = this.prereqs[preCourse];

    if (!preCourse.period) {
      /* The course is hidden and no prerequirement graph edge should be drawn! */
      continue;
    }

    var prereqElem = $(planView.escapeSelector('course-' + preCourse.code));

    var newPath = planView.paper.path(Course.calcPathString(this.element, prereqElem));
    this.prereqPaths.push({ path: newPath, course: preCourse });
  }
};

Course.prototype.updatePrereqPaths = function() {
  for (var i = 0; i < this.prereqPaths.length; i++) {
    var node          = this.prereqPaths[i],
        path          = node.path,
        prereqCourse  = node.course,
        $prereqElem   = $(planView.escapeSelector('course-' + prereqCourse.code));
    path.attr({ path: Course.calcPathString(this.element, $prereqElem) });
  }
};

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


Course.prototype.lock = function() {
  this.locked = true;
  this.element.draggable("disable");
  this.element.addClass("locked");
  /* Show lock icon on course div */
  var $img = $("img.course-locked", "#cloneable-imgs").clone();
  this.element.append($img);
};

Course.prototype.unlock = function() {
  this.locked = false;
  this.element.draggable("enable");
  this.element.removeClass("locked");
  /* Hide lock icon from course div */
  this.element.find("img.course-locked").detach();
};



/**
 * Course event listeners
 */

function courseClicked() {
  var course = $(this).data('object');

  // Clear prerequirement graphs
  course.clearPrereqPaths();

  // Reset hilights
  $('.course').removeClass('prereq-of').removeClass('prereq-to').removeClass('selected');
  $('.period').removeClass('receiver').removeClass("warning").removeClass("old-period");
   
  // Hilight selected course
  $(this).addClass('selected');

  // computing an appropriate prereqs string
  var prereqsz = 0;
  var prereqs_string, course_name_list_string = '';
  for (var array_index in course.prereqs) {
    prereq_course = course.prereqs[array_index]
    if (prereq_course) {
      prereqsz++;
      course_name_list_string += prereq_course.name + ', '
    }
  }
  if (prereqsz == 0) {
    prereqs_string = '-';
  } else {
    prereqs_string = String(prereqsz) + course_name_list_string;
  }

  // Show short course details on the controls pane
  var $courseDesc = $('#course-desc-block');
  $("#course-code").text(course.course_code); 
  $("#course-name").text(course.name);
  $("#course-points").text(course.credits);
  var prereqs = $.map(course.prereqs, function(course) { return course; });
  $("#course-prereqs-list").html(JST['templates/_schedule_prerequirement_courses'](
    {
      prereqs:            prereqs,
      no_prereqs_message: planView.translations.no_prereqs_message
    }
  ));

  $courseDesc.removeClass("hidden"); // TODO animate
  var $courseLockInput = $("#schedule-course-lock-input");
  $courseLockInput.removeAttr("disabled");
  $courseLockInput.prop("checked", course.locked);

  
  course.checkPrereqSatisfiability();

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
    var period = course.periods[array_index];
    if (period.laterOrEqual(planView.currentPeriod)) {
      period.element.addClass("receiver");

      if (period.id in course.prereqsUnsatisfiableIn) {
        period.element.addClass("warning");
      }
    } else {
      period.element.addClass("old-period");
    }
  }


  /* Draw requirement graphs for selected course */
  if (planView.settings.drawPrerequirementGraphs) {
    course.drawPrereqPaths();
  }
}


function courseDragStarted(event, ui) {
  var $element = ui.helper;

  if (!$element.hasClass("selected")) {
    /* The course is being dragged before having been clicked
     * and thus isn't selected yet. Call to clickhandler fixes that.
     * Notice that we must call the clickhandler in the correct context! */
    courseClicked.call(ui.helper[0]);
  }

  // Reset hilights
  $('.period').removeClass('receiver');

  // Dragging started, reset drop detection
  ui.helper.data('dropped', false);

  // Hilight the periods that have this course
  var periods = $element.data('object').periods;

  for (var array_index in periods) {
    periods[array_index].element.addClass("receiver");
  }

  var course = $element.data("object");
}


function courseBeingDragged(event, ui) {
  // Move prerequirement graphs
  var elem = ui.helper,
      course = elem.data('object');

  course.updatePrereqPaths();
}

function courseDragStopped(event, ui) {  // FIXME???
  if (!ui.helper.data('dropped')) {
    // Animate draggable back to its original position
    ui.helper.animate(ui.originalPosition, { 
      duration: 500,
      step: function(now, fx) {
        var $courseElem = $(this),
          course = $courseElem.data('object');

        // Update graphs too
        course.updatePrereqPaths();
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
};

return Course;
})();
