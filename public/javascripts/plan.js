var planView = {
  escapeSelector: function(myid) { 
    return '#' + myid.replace(/(:|\.)/g,'\\$1');
  },

  /**
   * Loads prereqs from JSON data.
   */
  loadPrereqs: function(data) {
    for (var array_index in data) {
      var rawData = data[array_index].course_prereq;
      
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
      
      new CourseInstance($course.data('object'), $period.data('object'), rawData.length);
    }
  },
  
  /**
   * Automatically arranges courses
   */
  autoplan: function() {
    $('.course').each(function(i, element){
      var course = $(element).data('object');
      
      course.postponeAfterPrereqs();   // Add course after its prereqs (those that have been located)
      
      if (!course.getPeriod()) {
        course.postponeTo(firstPeriod);
      }
      
      course.satisfyPostreqs();        // Move forward those courses that depend (recursively) on the newly added course
    });
  }
};


$(document).ready(function(){
  //status_div = $('#status');
  
  //var curriculum_id = $plan.data('curriculum-id');
  //var locale = $plan.data('locale');
  
  // Prepare courses
  $('.course').each(function(i, element){
    new Course($(element));
  });

  // Prepare periods
  var previousPeriod;
  var periodCounter = 0;
  $('.period').each(function(i, element){
    var period = new Period($(element));
    period.setSequenceNumber(periodCounter);
    
    if (!previousPeriod) {
      firstPeriod = period;
    }
    
    period.setPreviousPeriod(previousPeriod);
    previousPeriod = period;
    periodCounter++;
  });
  
  // Attach event listeners
  $("#autoplan").click(planView.autoplan);
  
  
  // Get course prereqs
  //$.getJSON('/' + locale + '/curriculums/' + curriculum_id + '/prereqs', planView.loadPrereqs);
  //$.getJSON('/' + locale + '/course_instances', planView.loadCourseInstances);
  var $plan = $('#plan');
  var prereqsPath = $plan.data('prereqs-path');     // '/' + locale + '/curriculums/' + curriculum_id + '/prereqs'
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


  planView.autoplan();
      
});
