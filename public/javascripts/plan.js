/**
 * Schedule view.
 */
var planView = {
  
  satisfyPrereqsAutomatically: true,
  periods: {},                         // Period objects, period_id => period object
  
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
      
      // If course is still unattached, put it on the first period
      if (!course.getPeriod()) {
        course.postponeTo(firstPeriod);
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
};


$(document).ready(function(){
  //status_div = $('#status');
  
  //var curriculum_id = $plan.data('curriculum-id');
  //var locale = $plan.data('locale');
  
  // Create a Course object for each course element
  $('.course').each(function(i, element){
    new Course($(element));
  });

  // Create a Period object for each period element
  var previousPeriod;
  var periodCounter = 0;
  $('.period').each(function(i, element){
    var period = new Period($(element));
    planView.addPeriod(period)
    
    if (!previousPeriod) {
      firstPeriod = period;
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


  // Put courses on their places
  planView.placeCourses();
  
  // Place new courses automatically
  planView.autoplan();
      
});
