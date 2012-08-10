(function() {
/**
 * Schedule view.
 */
var planView = window.planView = window.planView || {};
$.extend(window.planView, {
  periods: {},                         // Period objects, period_id => period object
  firstPeriod: false,
  settings: {
    satisfyReqsAutomatically: true,
    drawPrerequirementGraphs: true
  },
  
  initializeRaphael: function() {
    var planDiv = $('#plan');
    this.paper = Raphael(document.getElementById('plan'), planDiv.width(), planDiv.height());
    
    /* Align SVG canvas with the schedule table
     * and allow mouse events to pass through. */
    $('#plan svg').css({ 
      "position": "absolute", 
      "pointer-events": "none",
      "z-index": "1",
      "left": "0px"             // Needed for Firefox
    });

  },

  initializeFloatingSettingsPanel: function() {
    var $automaticArrangement = $("#schedule-automatic-arrangement"),
        $drawPrereqGraphs     = $("#schedule-draw-req-graphs"),
        $courseLock           = $("#schedule-course-lock");

    $automaticArrangement.find("img").popover({
      title:    planView.translations['popover_help_title'],
      content:  planView.translations['automatic_arrangement_help']
    });

    $courseLock.find("img").popover({
      title:    planView.translations['popover_help_title'],
      content:  planView.translations['course_lock_help']
    });

    /* Initialize checkboxes according to default values */
    $automaticArrangement.find("input").prop("checked", planView.settings.satisfyReqsAutomatically);

    $drawPrereqGraphs.find("input").prop("checked", planView.settings.drawPrerequirementGraphs);

    /* Add checkbox change listeners */

    $automaticArrangement.find("input").change(function(evt) {
      var shouldAutomaticallyArrange = $(this).prop("checked");
      planView.settings.satisfyReqsAutomatically = shouldAutomaticallyArrange;
      if (shouldAutomaticallyArrange) {
        /* Reset 'unschedulable' values so scheduling is possible in every case */
        $(".course").each(function(i) {
          $(this).data("object").unschedulable = false;
        });
        /* Schedule */
        planView.autoplan();
      }
    });

    $drawPrereqGraphs.find("input").change(function(evt) {
      var $selected = $("#plan .selected");
      if ($(this).prop("checked")) {
        planView.settings.drawPrerequirementGraphs = true;
        $selected.each(function(i) {
          $(this).data("object").drawPrereqPaths();
        });
      } else {
        planView.settings.drawPrerequirementGraphs = false;
        $selected.each(function(i) {
          $(this).data("object").clearPrereqPaths();
        });
      }
    });

    $courseLock.find("input").change(function(evt) {
      var $checkbox       = $(this),
          $selectedCourse = $(".course.selected", "#plan"),
          course          = $selectedCourse.data("object"); 

      var must_be_locked = $checkbox.prop("checked");
      if (must_be_locked) course.lock();
      else course.unlock();
    });
  },
  
  addPeriod: function(period) {
    this.periods[period.getId()] = period;
  },
  
  /**
   * Helper function for escaping css selectors
   */
  escapeSelector: function(myid) { 
    return '#' + myid.replace(/(:|\.)/g,'\\$1');
  },

  /**
   * Loads prereqs from JSON data.
   */
  loadPrereqs: function(data) {
    for (var array_index in data) {
      var rawData = data[array_index].course_prereq;
      
      // TODO: would be better to have a dictionary for storing Course objects
      
      // Find elements by course code
      var $course = $(planView.escapeSelector('course-' + rawData.course_code));
      var $prereq = $(planView.escapeSelector('course-' + rawData.prereq_code));
      
      // If either course is missing from DOM, skip
      if ($course.length < 1 || $prereq.length < 1) {
        continue;
      }
      
      $course.data('object').addPrereq($prereq.data('object'));
    }
  },

  /**
   * Loads course instances from JSON data
   */
  loadCourseInstances: function(data) {
    for (var array_index in data) {
      var rawData = data[array_index].course_instance;
      var $course = $(planView.escapeSelector('course-' + rawData.code));
      var $period = $('#period-' + rawData.period_id);
      
      if ($course.length < 1 || $period.length < 1) {
        continue;
      }
      
      var course = $course.data('object');
      var period = $period.data('object');
      var ci = new CourseInstance(course, period, rawData.length, rawData.id);
      period.addCourseInstance(ci);
      course.addCourseInstance(ci);
    }
  },
  
  /**
   * Places courses on periods according to the information provided in HTML
   */
  placeCourses: function() {
    $('.course').each(function(i, element){
      var course = $(element).data('object');
      var period_id = $(element).data('period');
      
      var period = planView.periods[period_id];
      if (period) {
        course.setPeriod(period);
      }
    });
  },
  
  /**
   * Automatically arranges courses
   */
  autoplan: function() {
    $('.course').each(function(i, element){
      var course = $(element).data('object');
      
      // Put course after its prereqs (those that have been attached)
      course.postponeAfterPrereqs();
      
      /* Sanity check */
      if (!course.getPeriod() && course.locked) {
        console.log("SANITY CHECK FAILED: Course is locked, but doesn't have a period!");
      }

      // If course is still unattached, put it on the first period
      var period = course.getPeriod();
      if ( !period && !course.unschedulable 
           || period && period.earlierThan(period.getCurrentPeriod())
         ) {
        course.postponeTo(planView.firstPeriod.getCurrentPeriod().getNextPeriod());
      }
      
      course.satisfyPostreqs();        // Move forward those courses that depend (recursively) on the newly added course
    });
  },
  
  save: function() {
    var path = $('#plan').data('schedule-path');
    
    var periods = {};
    $('.course').each(function(i, element){
      course = $(element).data('object');
      
      if (course.changed && course.courseInstance) {
        periods[course.id] = course.courseInstance.id;
      }
    });

    $.ajax({
      url: path,
      type: 'put',
      dataType: 'json',
      data: {periods: periods},
      async: false
    });
    
  }
});



$(document).ready(function(){
  //status_div = $('#status');
  
  //var curriculum_id = $plan.data('curriculum-id');
  //var locale = $plan.data('locale');
  
  // Make schedule controls always visible (i.e., sticky)
  var $scheduleControls     = $("#schedule-controls-container");
  var scheduleControlsOrig  = $scheduleControls.offset().top;
  $(window).scroll(function() {
    var winY = $(this).scrollTop();
    if (winY >= scheduleControlsOrig) {
      $scheduleControls.addClass("schedule-controls-fixed");
    } else {
      $scheduleControls.removeClass("schedule-controls-fixed");
    }
  });
  
  // Create a Course object for each course element
  $('.course').each(function(i, element){
    new Course($(element));
  });


  /* Make text in the plan div unselectable (to make UI less annoying). */
  $("#plan").disableSelection();

  // Create a Period object for each period element
  var previousPeriod;
  var periodCounter = 0;
  $('.period').each(function(i, element){
    var period = new Period($(element));
    planView.addPeriod(period);
    
    if (!previousPeriod) {
      planView.firstPeriod = period;
    }
    
    period.setSequenceNumber(periodCounter);
    period.setPreviousPeriod(previousPeriod);
    
    previousPeriod = period;
    periodCounter++;
  });
  
  // Attach event listeners
  $("#save-button").click(planView.save);
  
  
  // Get course prereqs by ajax
  var $plan = $('#plan');
  var prereqsPath   = $plan.data('prereqs-path');   // '/' + locale + '/curriculums/' + curriculum_id + '/prereqs'
  var instancesPath = $plan.data('instances-path'); // '/' + locale + '/course_instances'
  
  $.ajax({
    url: prereqsPath,
    dataType: 'json',
    success: planView.loadPrereqs,
    async: false
  });
  
  $.ajax({
    url: instancesPath,
    dataType: 'json',
    success: planView.loadCourseInstances,
    async: false
  });

  // Init Raphael
  planView.initializeRaphael();

  // Put courses on their places
  planView.placeCourses();
  
  // Place new courses automatically
  planView.autoplan();

  // Init floating control panel
  planView.initializeFloatingSettingsPanel();
      
});

})();