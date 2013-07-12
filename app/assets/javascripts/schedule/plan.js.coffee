

# Check that i18n strings have been loaded before this file
if not i18n
  throw "plan view i18n strings have not been loaded!"


class @PlanView

  @PERIOD_HEIGHT: 58
  @COURSE_WIDTH: 120
  @COURSE_MARGIN_X: 6
  @COURSE_MARGIN_Y: 6
  @COURSE_PADDING_Y: 3

  constructor: (@planUrl) ->
    @i18n = i18n  # accessible from the view like this: <span data-bind="text: $root.i18n['qwerty'] "></span>

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
    startTime = new Date().getTime()
    currentPeriodId = data['current_period_id']

    # Load periods
    periodCounter = 0
    previousPeriod = undefined
    for rawPeriod in data['periods']
      period = new Period(rawPeriod)

      period.sequenceNumber = periodCounter
      period.previousPeriod = previousPeriod
      previousPeriod.nextPeriod = period if previousPeriod

      @periods.push(period)
      @periodsById[period.id] = period

      previousPeriod = period
      periodCounter++

    console.log( "Loaded #{periodCounter} periods." )

    Period::currentPeriod = @periodsById[currentPeriodId]

    # Update period chronology (time) dependent flags
    period = Period::currentPeriod
    period.isNow(true)
    while period.previousPeriod?
      period = period.previousPeriod
      period.isOld(true)

    # Load scoped courses
    for rawSC in data['courses']
      course = new Course(rawSC)
      @courses.push(course)
      @coursesById[course.id] = course
      @coursesByAbstractCourseId[rawSC['abstract_course_id']] = course

      for prereqId in rawSC['prereq_ids']
        prereq = @coursesById[prereqId]
        course.addPrereq(prereq) if prereq

    console.log( "Loaded #{@courses.length} courses." )

    # Load competences TODO

    # Load course instances
    nCI = 0
    for rawCI in data['course_instances']
      course = @coursesByAbstractCourseId[rawCI['abstract_course_id']]
      period = @periodsById[rawCI['period_id']]
      length = rawCI['length']

      continue unless course? && period?
      courseInstance = new CourseInstance(rawCI['id'], course, period, length)

      course.addCourseInstance(courseInstance)
      nCI++

    console.log( "Loaded #{nCI}/#{data['course_instances'].length} course instances." )


    ko.applyBindings(this)

    # Load study plan course data
    nSPC = 0
    rawPlan = data['study_plan']
    for rawSPC in rawPlan['study_plan_courses']
      course = @coursesById[rawSPC['scoped_course_id']]
      unless course
        console.log "Unknown course #{rawSPC['scoped_course_id']}"
        continue

      periodId = rawSPC['period_id']
      if periodId
        period = @periodsById[periodId]

        if period
          course.setPeriod(period)
          course.updatePosition()

          # Save original data
          course.oPeriodId = period.id
          course.oLength = course.length if course.length > 0
          course.oCourseInstanceId = course.courseInstance.id if course.courseInstance?

      nSPC++

    console.log( "Loaded #{nSPC}/#{rawPlan['study_plan_courses'].length} study plan courses." )

    # Load passed courses
    nUC = 0
    for rawUC in data['passed_courses']
      course = @coursesByAbstractCourseId[rawUC['abstract_course_id']]
      unless course
        console.log "Unknown course #{rawUC['abstract_course_id']}"
        continue

      course.setAsPassed(rawUC['course_instance_id'], rawUC['grade'])
      course.oGrade = rawUC['grade']
      nUC++

    console.log( "Loaded #{nUC}/#{data['passed_courses'].length} user courses." )

    # Automatically schedule new courses
    schedule = new Scheduler(@courses)
    schedule.scheduleUnscheduledCourses()

    for courseId, period of schedule.schedule
      course = @coursesById[courseId]
      unless course
        console.log "Unknown course #{courseId}"
        continue

      course.setPeriod(period)
      course.updatePosition()

    # Update course ordering related warnings
    for course in @courses
      course.updateReqWarnings()

    # Set the viewport position automatically to show the current period and the near future
    topOffSet = $('div.period.now').offset().top
    $(window).scrollTop( topOffSet - 2 * @constructor.PERIOD_HEIGHT )

    # Get time elapsed since start to show current time usage
    endTime = new Date().getTime();
    console.log("Parsing the data took #{endTime - startTime} milliseconds.")


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
    #   "plan_courses": [
    #     {"scoped_course_id": 71, "period_id": 1, "course_instance_id": 45},
    #     {"scoped_course_id": 35, "period_id": 2},
    #     {"scoped_course_id": 45, "period_id": 2, "credits": 3, "length": 1},
    #     {"scoped_course_id": 60, "period_id": 3, "course_instance_id": 32, "credits": 8, "length": 2, "grade": 3},
    #     ...
    #   ]
    # }
    plan_courses = []
    for course in @courses
      if course.hasChanged()
        console.log( "Course #{course.name} was changed. Pushing to be saved." )
        plan_courses.push(course.toJson())
        course.resetOriginals()

    if plan_courses.length == 0
      console.log( 'No plan_course was changed. No reason to put.' )
      return

    console.log( "A total of #{plan_courses.length} courses changed. Starting the put." )

    $.ajax
      url: @planUrl,
      type: 'put',
      dataType: 'json',
      data: { 'plan_courses': JSON.stringify(plan_courses) }
