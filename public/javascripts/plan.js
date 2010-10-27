function jq(myid) { 
  return '#' + myid.replace(/(:|\.)/g,'\\$1');
}

function logger(message) {
  status_div.append(message);
}


function resetLogger() {
  status_div.empty();
}

function Period(id, element) {
  this.id = id;
  this.element = element;
  this.nextPeriod = false;
   
  this.slots = Array();    // Boolean array of slots occupied by previous periods
  this.courses = Array();  // Array of course elements
}

Period.prototype.addCourse = function(course_element) {
  var period_div_pos = $(this.element).position();
  
  // Occupy slots
  var freeSlot = this.slots.length;
  for (i = 0; i < this.slots.length; i++) {
    if (!this.slots[i]) {
      freeSlot = i;
    }
  }
  
  this.slots[i] = true;
  
  course_element.css('left', period_div_pos.left + freeSlot * 100);
  course_element.css('top', period_div_pos.top + 2);
  
  
  // Free the original slot
}

/**
 * Returns true if this period has any of the given courses. Parameter is an array of ids.
 */
Period.prototype.hasCourse = function(courses) {
  for (var period_course_index in this.courses) {
    period_course = this.courses[period_course_index];
    
    for (var testing_course_index in courses) {
      if (period_course.id = courses[testing_course_index]) {
        return true;
      }
    }
  }
  
  return false;
}

/**
 * courses: array of ids
 */
Period.prototype.postponeCourses = function(course_ids) {
  for (var course_index in course_ids) {
    var course_id = course_ids[course_index];
    
    for (var p in period.courses) {
    }
  }
}

function dropCourse(event, ui) {
  var period_div = $(this);                              // Period div on which the course is dropped
  var course_div = ui.draggable;                         // Course div being dragged
  var course_id = course_div.data("code");
  
  // Reset all hilights
  $(".period").removeClass("receiver");
  
  // Find the course instance
  if (period_div.data('course-instances')[course_id]) {
    // Align course with this period
    //period.addCourse(course_div);
    moveCourse(course_div, period_div);
  } else {
    // If there is no instance on that period, revert
    alert("No instance");
    // TODO: revert position
    return;
  }
  
  // Update length
  // TODO
}

function CourseInstance(course_instance_id, abstract_course_id, period_id) {
  this.course_instance_id = course_instance_id
  this.abstract_course_id = abstract_course_id
  this.period_id = period_id
}

function startCourseDrag(event, ui) {
  // Hilight the periods that have this course
  var course = ui.helper;
  var periods = course.data("periods");
  
  for (var array_index in periods) {
    var period = periods[array_index];
    
    period.addClass("receiver");
  }
}

function loadPrereqs(data) {
  for (var array_index in data) {
    var prereq = data[array_index].course_prereq;
    var course_code = prereq.course_code;
    var prereq_code = prereq.prereq_code;
    var course = $(jq('course-' + course_code));
    var prereq = $(jq('course-' + prereq_code));
    
    if (course.length < 1 || prereq.length < 1) {
      continue;
    }
    
    course.data('prereqs')[prereq_code] = prereq;
    prereq.data('prereq-to')[course_code] = course;
  }
}

/**
 * Loads course instances from JSON data
 */
function loadCourseInstances(data) {
  for (var array_index in data) {
    var raw_instance = data[array_index].course_instance;
    var course = $(jq('course-' + raw_instance.code));
    var period = $('#period-' + raw_instance.period_id);
    
    if (course.length < 1 || period.length < 1) {
      continue;
    }
    
    // Add course to period
    period.data("course-instances")[raw_instance.code] = course;
    
    // Add period to course
    course.data("periods")[raw_instance.period_id] = period;
  }
}

function autoplan() {

  // Add all courses to the first period
  $('.course').each(function(i,element){
    var course = $(element);
    var course_id = course.data('code');
    firstPeriod.data('courses')[course_id] = course;
    
    course.data('period', firstPeriod);
  });
  
  var period = firstPeriod;
  while (true) {
    var nextPeriod = period.data('next-period');
    if (!nextPeriod) {
      alert("Not enough periods");
      break;
    }
    
    // See which courses depend on some course on this period.
    var moveForward = {};
    var periodCourses = period.data('courses');
    for (var course_index in periodCourses) {
      var course = periodCourses[course_index];
      var course_id = course.data('code');
      
      // If the course is not arranged on this period, move forward.
      if (!period.data('course-instances')[course_id]) {
        moveForward[course_id] = course;
      }
      
      // Check each prereq. If a prereq of a course is on this period, mark the course to be moved forward.
      var prereqs = course.data('prereqs');
      for (var prereq_index in prereqs) {
        var prereq = prereqs[prereq_index];
        
        if (period.data('courses')[prereq.data('code')]) {
          moveForward[course_id] = course;
        }
      }
    }
    
    // Move the marked courses forward
    var forward_counter = 0;
    for (var course_index in moveForward) {
      var course = moveForward[course_index];
      moveCourse(course, nextPeriod);
      forward_counter++;
    }
    
    if (forward_counter < 1) {
      break;
    }
    
    period = nextPeriod;
  }
  
  return false;
}

function moveCourse(course, period) {
  // De-occupy current slot
  var currentPeriod = course.data('period');
  var currentSlot = course.data('slot');
  
  if (currentSlot) {
    //currentPeriod.data('slots')[]
  }
  
  // Remove course from previous period
  delete currentPeriod.data('courses')[course.data('code')];
  
  course.data('period', period);
  period.data('courses')[course.data('code')] = course;
  
  // Move the div
  var period_div_pos = period.position();
  //course.css('left', period_div_pos.left + freeSlot * 100);
  course.css('top', period_div_pos.top + 2);
  
  // Occupy slots
}

function clickCourse() {
  // Hilight prereqs
  var prereqs = $(this).data('prereqs');
  for (var array_index in prereqs) {
    var course = prereqs[array_index];
    course.addClass("prereq-of");
  }
  
  // Hilight courses for which this is a prereq
  var prereqto = $(this).data('prereq-to');
  for (var array_index in prereqto) {
    var course = prereqto[array_index];
    course.addClass("prereq-to");
  }
  
}

$(document).ready(function(){
  status_div = $('#status');
  var curriculum_id = $('#plan').data('curriculum-id');
  var locale = $('#plan').data('locale');
  
  // Prepare courses
  $(".course")
    .draggable({
      containment: 'parent',
      distance: 5,
      start: startCourseDrag
    })
    .click(clickCourse)
    .each(function(i, element){
      $(element).data('periods', {});     // Periods on which this course is arranged
      $(element).data('prereqs', {});     // Prerequisite courses
      $(element).data('prereq-to', {});   // Courses for which this course is a prereq
      $(element).data('slot', false);
    });

  // Prepare periods
  var previousPeriod;
  $(".period")
    .droppable({
      drop: dropCourse
    })
    .each(function(i, element){
      // Link periods to each other
      var period = $(element);
      period.data('courses', {});                        // Courses that have been put to that period
      period.data('course-instances', {});               // Courses that are available on that period
      period.data('slots', []);
      period.data('previous-period', previousPeriod);
      if (previousPeriod) {
        previousPeriod.data('next-period', period);
      } else {
        firstPeriod = period;
      }
      previousPeriod = period;
    });

  // Attach period objects to periods
//   periods = Array();
//   var previousPeriod = false;
//   $(".period").each(function(i,element) {
//     var period = new Period($(this).data("id"), element);   // Create a new period object
//     if (previousPeriod) {
//       previousPeriod.nextPeriod = period;
//     }
//     previousPeriod = period;
//     
//     periods.push(period);
//     $(this).data("period", period);                         // Attach the object to the element
//   });
  
  // Attach event listeners
  $("#autoplan").click(autoplan);
  
  // Get course prereqs
  $.getJSON('/' + locale + '/curriculums/' + curriculum_id + '/prereqs', loadPrereqs);
  $.getJSON('/' + locale + '/course_instances', loadCourseInstances);
  

});
