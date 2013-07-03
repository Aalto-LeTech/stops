class @PlanView
  
  constructor: (@planUrl) ->
    @periods = []
    @periodsById = {}
    
    @courses = []
    @coursesById = {}
    
    @selectedCourse = ko.observable()
    
    # Period objects, period_id => period object
#     @currentPeriod: false                # Current period object
#     @firstPeriod: false
#     @settings: {
#       satisfyReqsAutomatically: true,
#       drawPrerequirementGraphs: true
#     }
# 
#   initializeRaphael: ->
#     planDiv = $('#plan')
#     this.paper = Raphael(document.getElementById('plan'), planDiv.width(), planDiv.height())
# 
#     # Align SVG canvas with the schedule table
#     # and allow mouse events to pass through.
#     $('#plan svg').css({ 
#       "position": "absolute", 
#       "pointer-events": "none",
#       "z-index": "1",
#       "left": "0px"             # Needed for Firefox
#     })
# 
# 
#   initializeFloatingSettingsPanel: ->
#     $automaticArrangement = $("#schedule-automatic-arrangement")
#     $drawPrereqGraphs     = $("#schedule-draw-req-graphs")
#     $courseLock           = $("#schedule-course-lock")
# 
#     $automaticArrangement.find("img").popover({
#       title:    planView.translations['popover_help_title'],
#       content:  planView.translations['automatic_arrangement_help']
#     })
# 
#     $courseLock.find("img").popover({
#       title:    planView.translations['popover_help_title'],
#       content:  planView.translations['course_lock_help']
#     })
# 
#     # Initialize checkboxes according to default values 
#     $automaticArrangement.find("input").prop("checked", planView.settings.satisfyReqsAutomatically)
# 
#     $drawPrereqGraphs.find("input").prop("checked", planView.settings.drawPrerequirementGraphs)
# 
#     # Add checkbox change listeners 
#     $automaticArrangement.find("input").change (evt) ->
#       shouldAutomaticallyArrange = $(this).prop("checked")
#       planView.settings.satisfyReqsAutomatically = shouldAutomaticallyArrange
#       if (shouldAutomaticallyArrange)
#         # Reset 'unschedulable' values so scheduling is possible in every case 
#         $(".course").each (i) ->
#           $(this).data("object").unschedulable = false
#         
#         # Schedule 
#         planView.autoplan()
#     
# 
#     $drawPrereqGraphs.find("input").change (evt) ->
#       $selected = $("#plan .selected")
#       if ($(this).prop("checked"))
#         planView.settings.drawPrerequirementGraphs = true
#         $selected.each (i) ->
#           $(this).data("object").drawPrereqPaths()
#       else
#         planView.settings.drawPrerequirementGraphs = false
#         $selected.each (i) ->
#           $(this).data("object").clearPrereqPaths()
# 
# 
#     $courseLock.find("input").change (evt) ->
#       $checkbox       = $(this)
#       $selectedCourse = $(".course.selected", "#plan")
#       course          = $selectedCourse.data("object")
# 
#       must_be_locked = $checkbox.prop("checked")
#       if (must_be_locked)
#         course.lock()
#       else
#         course.unlock()
#     
# 
#   addPeriod: (period) ->
#     this.periods[period.getId()] = period
# 
# 
#   # Helper function for escaping css selectors
#   escapeSelector: function(myid) { 
#     return '#' + myid.replace(/(:|\.)/g,'\\$1');
#   },
# 
# 

  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.parsePlan(data)

  # Loads plan from JSON data
  parsePlan: (data) ->
    # Load periods
    current_period_id = data['current_period_id']
    
    raw_periods = data['periods']
    periodCounter = 0
    previousPeriod = undefined
    for raw_period in raw_periods
      period = new Period(raw_period)
      
      period.isCurrentPeriod = true if period.id == current_period_id
      period.sequenceNumber = periodCounter
      period.previousPeriod = previousPeriod
      previousPeriod.nextPeriod = period if previousPeriod
      
      @periods.push(period)
      @periodsById[period.id] = period
      
      previousPeriod = period
      periodCounter++
    
    Period::currentPeriod = @periodsById[current_period_id]
      
    # Load scoped courses
    raw_courses = data['courses']
    for raw_course in raw_courses
      course = new Course(raw_course)
      @courses.push(course)
      @coursesById[course.id] = course
    
    
    ko.applyBindings(this)
    
    # Load study plan courses
    raw_plan = data['study_plan']
    for plan_course in raw_plan['study_plan_courses']
      course = @coursesById[plan_course['scoped_course_id']]
      unless course
        console.log "Unknown course #{plan_course['scoped_course_id']}"
        continue
      
      period_id = plan_course['period_id']
      if period_id
        period = @periodsById[period_id] 
      
        if period
          course.setPeriod(period)
          course.updatePosition()
    

#   #Loads prereqs from JSON data.
#   loadPrereqs: (data) ->
#     for (array_index in data)
#       rawData = data[array_index].course_prereq
# 
#       # TODO: would be better to have a dictionary for storing Course objects
# 
#       # Find elements by course code
#       $course = $(planView.escapeSelector('course-' + rawData.course_code))
#       $prereq = $(planView.escapeSelector('course-' + rawData.prereq_code))
# 
#       # If either course is missing from DOM, skip
#       continue if ($course.length < 1 || $prereq.length < 1)
# 
#       $course.data('object').addPrereq($prereq.data('object'))
# 
# 
#   # Loads course instances from JSON data
#   loadCourseInstances: (data) ->
#     for (array_index in data)
#       rawData = data[array_index].course_instance
#       $course = $(planView.escapeSelector('course-' + rawData.course_code))
#       $period = $('#period-' + rawData.period_id)
# 
#       continue if ($course.length < 1 || $period.length < 1)
# 
#       course = $course.data('object')
#       period = $period.data('object')
#       ci = new CourseInstance(course, period, rawData.length, rawData.id)
#       period.addCourseInstance(ci)
#       course.addCourseInstance(ci)
# 
# 
#   # Places courses on periods according to the information provided in HTML
#   placeCourses: ->
#     $('.course').each (i, element) ->
#       course = $(element).data('object')
#       period_id = $(element).data('period')
# 
#       period = planView.periods[period_id]
#       course.setPeriod(period) if (period)
# 
# 
  # Automatically arranges courses that are not on any period
  autoplan: ->
    for course in @courses
      continue if course.period?
      
      #course.period = Period::currentPeriod
      
      # Put course after its prereqs (those that have been attached)
      course.postponeAfterPrereqs()
      
      # Sanity check 
      #if (!course.getPeriod() && course.locked)
      #  console.log("SANITY CHECK FAILED: Course is locked, but doesn't have a period!")

      # If course is still unattached, put it on the first period
      #period = course.period
      unless course.period   #(!period? && !course.unschedulable) || (period && period.earlierThan(period.getCurrentPeriod())
        course.postponeTo(Period::currentPeriod)
      
      course.satisfyPostreqs()        # Move forward those courses that depend (recursively) on the newly added course


  save: ->
    # {
    #   "study_plan_courses": [
    #     {"period_id": 1, "scoped_course_id": 71},
    #     {"period_id": 2, "scoped_course_id": 35},
    #     ...
    #   ]
    # }
    study_plan_courses = []
    for course in @courses
      study_plan_courses.push(course.toJson()) # TODO if course.changed
    
    $.ajax
      url: @planUrl,
      type: 'put',
      dataType: 'json',
      data: { 'study_plan_courses': JSON.stringify(study_plan_courses) }
