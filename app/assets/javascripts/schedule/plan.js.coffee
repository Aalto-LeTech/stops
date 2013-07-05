class @PlanView

  @PERIOD_HEIGHT: 58
  @COURSE_WIDTH: 120
  @COURSE_MARGIN_X: 6
  @COURSE_MARGIN_Y: 6
  @COURSE_PADDING_Y: 3
  
  constructor: (@planUrl) ->
    @periods = []
    @periodsById = {}
    
    @courses = []
    @coursesById = {}                # scoped_course_id => Course
    @coursesByAbstractCourseId = {}  # abstract_course_id => Course
    
    @selectedCourse = ko.observable()
    #this.initializeRaphael()
    
    # TODO:
    # old periods
    # add warning if courses are in wrong order
    # click background -> unselect courses
    
    
  initializeRaphael: ->
    #planDiv = $('#plan')
    
    #this.paper = Raphael(planDiv.get(0), planDiv.width(), planDiv.height())
    #PlanView::paper = Raphael(document.getElementById('plan'), planDiv.width(), planDiv.height())

    # Align SVG canvas with the schedule table
    # and allow mouse events to pass through.
#     $('#plan svg').css({ 
#       "position": "absolute", 
#       "pointer-events": "none",
#       "z-index": "1",
#       "left": "0px"             # Needed for Firefox
#     })
# 
# 
#   initializeFloatingSettingsPanel: ->
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

  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.parsePlan(data)


  # Loads plan from JSON data
  parsePlan: (data) ->
    # Load periods
    current_period_id = data['current_period_id']
    
    periodCounter = 0
    previousPeriod = undefined
    for raw_period in data['periods']
      period = new Period(raw_period)
      
      period.sequenceNumber = periodCounter
      period.previousPeriod = previousPeriod
      previousPeriod.nextPeriod = period if previousPeriod
      
      @periods.push(period)
      @periodsById[period.id] = period
      
      previousPeriod = period
      periodCounter++
    
    Period::currentPeriod = @periodsById[current_period_id]
    
    # Load scoped courses
    for raw_course in data['courses']
      course = new Course(raw_course)
      @courses.push(course)
      @coursesById[course.id] = course
      @coursesByAbstractCourseId[raw_course['abstract_course_id']] = course
      
      for prereq_id in raw_course['prereq_ids']
        prereq = @coursesById[prereq_id]
        course.addPrereq(prereq) if prereq
    
    # Load course instances
    for raw_instance in data['course_instances']
      course = @coursesByAbstractCourseId[raw_instance['abstract_course_id']]
      period = @periodsById[raw_instance['period_id']]
      length = raw_instance['length']
      
      continue unless course? && period?
      course_instance = new CourseInstance(raw_instance['id'], course, period, length)
      
      course.addCourseInstance(course_instance)
      
    
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
    
    
    # Automatically schedule new courses
    schedule = new Scheduler(@courses)
    schedule.scheduleUnscheduledCourses()

    for courseId,period of schedule.schedule
      course = @coursesById[courseId]
      unless course
        console.log "Unknown course #{courseId}"
        continue
    
      course.setPeriod(period)
      course.updatePosition()


  unselectCourses: (data, event) ->
    this.selectCourse()

  selectCourse: (course) ->
    selectedCourse = @selectedCourse()
    
    # Reset hilights
    if selectedCourse
      for period in selectedCourse.periods
        period.hilight(false)
    
      selectedCourse.hilightSelected(false)
      
      for id,other of selectedCourse.prereqTo
        other.hilightPrereqTo(false)
        
      for id,other of selectedCourse.prereqs
        other.hilightPrereq(false)
    
    # Select new course
    @selectedCourse(course)
    
    return unless course
    
    # Hilight selected
    course.hilightSelected(true)
    
    # Hilight prereqs
    for id,other of course.prereqs
      other.hilightPrereq(true)

    # Hilight courses for which this is a prereq
    for id,other of course.prereqTo
      other.hilightPrereqTo(true)
    
    # Hilight the periods that have this course
    for period in course.periods
      period.hilight(true)
      
    
#       if (period.laterOrEqual(planView.currentPeriod)) {
#         period.element.addClass("receiver");
# 
#         if (period.id in course.prereqsUnsatisfiableIn) {
#           period.element.addClass("warning");
#         }
#       } else {
#         period.element.addClass("old-period");
#       }
#     }
# 
# 
#     # Draw requirement graphs for selected course */
#     if (planView.settings.drawPrerequirementGraphs) {
#       course.drawPrereqPaths();
#     }
#   }


  save: ->
    # {
    #   "study_plan_courses": [
    #     {"period_id": 1, "course_instance_id": 45, "scoped_course_id": 71},
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
