

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

    @coursesToSave = [] # List of courses to be saved. Managed by @save()
    @coursesRejected = [] # List of courses rejected on save by the server. Managed by @save()

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
    console.log("Starts loading data...")


    # Load periods
    currentPeriodId = data['current_period_id']

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

    console.log("Loaded #{periodCounter} periods.")

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

    console.log("Loaded #{@courses.length} courses.")


    # Load competences

    # TODO


    # Load course instances
    nCI = 0
    for rawCI in data['course_instances']

      # It can be expected that many instances are irrelevant
      period = @periodsById[rawCI['period_id']]
      continue unless period?

      course = @coursesByAbstractCourseId[rawCI['abstract_course_id']]
      continue unless course?

      length = rawCI['length']
      courseInstance = new CourseInstance(rawCI['id'], course, period, length)
      course.addCourseInstance(courseInstance)
      nCI++

    console.log("Loaded #{nCI}/#{data['course_instances'].length} course instances.")


    # Load study plan course data
    nSPC = 0
    rawPlan = data['study_plan']
    for rawSPC in rawPlan['study_plan_courses']
      course = @coursesById[rawSPC['scoped_course_id']]
      unless course
        console.log("Unknown course #{rawSPC['scoped_course_id']}!")
        continue

      periodId = rawSPC['period_id']
      if periodId
        period = @periodsById[periodId]
        if not period
          console.log("Unknown period ID #{periodId}")
          continue

        # Only set the variable to avoid unnecessary repetition
        course.period = period
      nSPC++

    console.log("Loaded #{nSPC}/#{rawPlan['study_plan_courses'].length} study plan courses.")


    # Load passed courses
    nUC = 0
    for rawUC in data['passed_courses']
      course = @coursesByAbstractCourseId[rawUC['abstract_course_id']]
      unless course
        console.log "Unknown course #{rawUC['abstract_course_id']}"
        continue

      # Only set the variables to avoid unnecessary repetition
      course.passedInstance = course.instancesById[rawUC['course_instance_id']]
      course.grade(rawUC['grade'])
      nUC++

    console.log("Loaded #{nUC}/#{data['passed_courses'].length} user courses.")


    # Automatically schedule unscheduled courses
    schedule = new Scheduler(@courses)
    schedule.scheduleUnscheduledCourses()

#    nAS = 0
#    for courseId, isModified of schedule.modified
#      # Only deal with modified courses
#      continue if not isModified
#      course = @coursesById[courseId]
#      unless course
#        console.log "Unknown course #{courseId}"
#        continue

#      # Only set the variable to avoid unnecessary repetition
#      course.period = schedule.schedule[courseId]
#      nAS++

#    console.log("Automatically scheduled #{nAS}/#{@courses.length} courses.")


    # apply ko bindings
    console.log("Applying bindings...")
    preBindTime = new Date().getTime()
    ko.applyBindings(this)
    postBindTime = new Date().getTime()


    # Set periods, update positions and saves the 'originals'
    # All done in the same loop (and rather complicatedly) to avoid repeating
    # operations.
    console.log("Setting the courses to the periods...")
    for course in @courses
      # If the course is passed, set accordingly
      if course.passedInstance
        course.period = undefined
        course.setAsPassed(course.passedInstance.id, course.grade())
        course.resetOriginals()
      # Else if the course was moved by the scheduler
      else if schedule.modified[course.id]
        course.resetOriginals()
        course.period = undefined
        course.setPeriod(schedule.schedule[course.id])
        course.updatePosition()
      # If the course has a place to go to
      else if course.period
        period = course.period
        course.period = undefined
        course.setPeriod(period)
        course.updatePosition()
        course.resetOriginals()
      # Hmmh...?
      else
        console.log("WARNING: A vagabond course: #{course}!")
        course.resetOriginals()


    # Update course ordering related warnings
    console.log("Updating course ordering warnings...")
    for course in @courses
      course.updateReqWarnings()


    # Set the viewport position automatically to show the current period and the near future
    console.log("Setting the viewport...")
    topOffSet = $('div.period.now').offset().top
    $(window).scrollTop(topOffSet - 2 * @constructor.PERIOD_HEIGHT)


    # Log time used from start to bind and here
    endTime = new Date().getTime();
    console.log("Parsing & modelling the plan data took #{preBindTime - startTime} (preBind) + #{postBindTime - preBindTime} (bind) + #{endTime - postBindTime} (postBind) = #{endTime - startTime} (total) milliseconds.")


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
    @coursesRejected = []   # FIXME: Not used atm.
    @coursesToSave = []     # courses
    planCoursesToSave = []  # their JSON representation for sending
    for course in @courses
      if course.hasChanged()
        console.log("Course \"#{course.name}\" was changed. Pushing to be saved.")
        @coursesToSave.push(course)
        planCoursesToSave.push(course.toJson())

    if @coursesToSave.length == 0
      console.log('No plan_course was changed. No reason to put.')
      return

    console.log("A total of #{@coursesToSave.length} courses changed. Starting the put.")

    $.ajax
      url: @planUrl,
      type: 'put',
      dataType: 'json',
      data: { 'plan_courses': JSON.stringify(planCoursesToSave) },
      success: (data) =>
        if data['status'] == 'ok'
          accepted = data['accepted']
          if accepted?
            for course in @coursesToSave
              if accepted[course.id]
                console.log("Course \"#{course.name}\" was successfully saved.")
                course.resetOriginals()
              else
                console.log("ERROR: Course \"#{course.name}\" was rejected by the server! Saving failed!")
                @coursesRejected.push(course)  # FIXME: Not used atm.
