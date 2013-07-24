# Check that i18n strings have been loaded before this file
if not i18n
  throw "plan view i18n strings have not been loaded!"

class @PlanView

  @PERIOD_HEIGHT: 58
  @COURSE_WIDTH: 120
  @COURSE_MARGIN_X: 6
  @COURSE_MARGIN_Y: 6
  @COURSE_PADDING_Y: 3

  @FIXME: 42


  constructor: (@planUrl) ->
    # i18n string support. Accessible from the view like this:
    #   <span data-bind="text: $root.i18n['qwerty'] "></span>
    @i18n = i18n

    @selectedObject = ko.observable()
    @selectedObjectType = ko.observable()

#    @showAsEditable = ko.observable(false)

    # List of courses to be saved and rejected when tried to save.
    # Both are used and managed at @save()
    @coursesToSave = []
    @coursesRejected = []

    @constructor.FIXME = @


#  doShowAsEditable: ->
#    @showAsEditable(true)
#    #console.log("showAsEditable -> #{@showAsEditable()}!")


#  noShowAsEditable: ->
#    @showAsEditable(false)
#    #console.log("showAsEditable -> #{@showAsEditable()}!")


  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.loadJson(data)


  # Loads the plan from JSON data
  loadJson: (data) ->
    startTime = new Date().getTime()
    console.log("Starts loading data...")

    # Load periods
    Period::createFromJson(data['periods'])
    console.log("Loaded #{Period::ALL.length} periods.")

    # Load courses
    Course::createFromJson(data['courses'], data['user_courses'])
    console.log("Loaded #{Course::ALL.length} courses.")

    # Load competences
    Competence::createFromJson(data['competences'])
    console.log("Loaded #{Competence::ALL.length} competences.")

    # Automatically schedule unscheduled (new) courses
    schedule = new Scheduler(Course::ALL)
    schedule.scheduleUnscheduledCourses()


    # Set periods and save the 'originals'
    console.log("Setting the courses to the periods...")
    for course in Course::ALL
      # If the course was moved by the scheduler
      if schedule.moved[course.scopedId]
        course.resetOriginals()
        course.period = undefined
        course.setPeriod(schedule.schedule[course.scopedId])
      # Else if the course has a place to go to
      else if course.period
        period = course.period
        course.period = undefined
        course.setPeriod(period)
        course.resetOriginals()
      # Hmmh...?
      else
        console.log("WARNING: A vagabond course: #{course}!")
        course.resetOriginals()

      # Update course ordering related warnings
      course.updateReqWarnings()


    # Only because ko bindings seem unable to refer to class vars
    @periods = Period::ALL
    @courses = Course::ALL
    @competences = Competence::ALL
    # Apply ko bindings
    console.log("Applying bindings...")
    preBindTime = new Date().getTime()
    ko.applyBindings(this)
    postBindTime = new Date().getTime()


    # Update positions
    for course in Course::ALL
      course.updatePosition() if course.period

    # Initialize tooltips
    #$('div.plan div.period div.credits span').tooltip(placement: 'left')
    #$('div.plan div.course').tooltip(placement: 'bottom', delay: 1500)
    #$('div.well div.progress').tooltip(placement: 'bottom', delay: 1000)

    # Autoscroll the viewport to show the current period and the near future
    # FIXME: Don't move the viewport, but the scrollable div.
    #console.log("Autoscrolling the viewport...")
    #topOffSet = $('div.period.now').offset().top
    #$(window).scrollTop(topOffSet - 2 * @constructor.PERIOD_HEIGHT)

    # Log time used from start to bind and here
    endTime = new Date().getTime();
    console.log("Parsing & modelling the plan data took #{preBindTime - startTime} (preBind) + #{postBindTime - preBindTime} (bind) + #{endTime - postBindTime} (postBind) = #{endTime - startTime} (total) milliseconds.")


  unselectObjects: (data, event) ->
    @selectObject()


  selectObject: (object) ->

    # Deselect the old object
    selectedObject = @selectedObject()

    # Reset hilights
    if selectedObject
      selectedObject.isSelected(false)

      if selectedObject instanceof Course

        for period in selectedObject.periods
          period.isReceiver(false)

        for scopedId, other of selectedObject.prereqTo
          other.hilightPrereqTo(false)

        for scopedId, other of selectedObject.prereqs
          other.hilightPrereq(false)


      else if selectedObject instanceof Competence

        for prereq in selectedObject.prereqs
          prereq.hilightPrereq(false)


    # Select the new object
    #console.log("Deselected [#{@selectedObjectType()}] #{selectedObject}")
    @selectedObjectType(undefined)
    @selectedObject(undefined)
    @selectedObjectType('Course') if object instanceof Course
    @selectedObjectType('Period') if object instanceof Period
    @selectedObjectType('Competence') if object instanceof Competence
    @selectedObject(object)
    #console.log("Selected [#{@selectedObjectType()}] #{object}")

    return unless object

    # Hilight selected
    object.isSelected(true)

    if object instanceof Course
      # Hilight prereqs
      for scopedId, other of object.prereqs
        other.hilightPrereq(true)

      # Hilight courses for which this is a prereq
      for scopedId, other of object.prereqTo
        other.hilightPrereqTo(true)

      # Hilight the periods that have this course
      for period in object.periods
        period.isReceiver(true)

      #console.log("customized: #{object.code} = #{object.customized()} : (#{object.credits()} vs #{object.scopedCredits}, #{object.length()} vs #{object.courseInstance?.length})")

    else if object instanceof Competence

      for prereq in object.prereqs
        prereq.hilightPrereq(true)


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
    @coursesRejected = []   # FIXME: Not used atm. Add a user notifier!
    @coursesToSave = []     # courses
    planCoursesToSave = []  # their JSON representation for sending
    for course in Course::ALL
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
              if accepted[course.scopedId]
                console.log("Course \"#{course.name}\" was successfully saved.")
                course.resetOriginals()
              else
                console.log("ERROR: Course \"#{course.name}\" was rejected by the server! Saving failed!")
                @coursesRejected.push(course)  # FIXME: Not used atm.
