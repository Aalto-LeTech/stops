# Check that i18n strings have been loaded before this file
if not i18n
  throw "plan view i18n strings have not been loaded!"

class @PlanView

  @PERIOD_HEIGHT: 58
  @COURSE_WIDTH: 120
  @COURSE_MARGIN_X: 6
  @COURSE_MARGIN_Y: 6
  @COURSE_PADDING_Y: 3
  ISREADY: false

  constructor: (@planUrl) ->
    # i18n string support. Accessible from the view like this:
    #   <span data-bind="text: $root.i18n['qwerty'] "></span>
    @i18n = i18n

    @selectedObject = ko.observable()
    @selectedObjectType = ko.observable()

    @showAsEditable = false
    #@showAsEditable = ko.observable(false)

    # List of courses to be saved and rejected when tried to save.
    # Both are used and managed at @save()
    @coursesToSave = []
    @coursesRejected = []


  showAsEditableInit: ->
    #dbg("showAsEditableInit()!")
    @showAsEditable = false
    $('#credits #in, #grade #in, #length #in').hide()


  doShowAsEditable: ->
    if not @showAsEditable
      @showAsEditable = true
      #dbg("showAsEditable -> #{@showAsEditable}!")
      $('#credits #out, #grade #out, #length #out').hide()
      $('#credits #in, #grade #in, #length #in').show()


  noShowAsEditable: ->
    if @showAsEditable
      @showAsEditable = false
      #dbg("showAsEditable -> #{@showAsEditable}!")
      $('#credits #in, #grade #in, #length #in').hide()
      $('#credits #out, #grade #out, #length #out').show()


  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.loadJson(data)


  # Loads the plan from JSON data
  loadJson: (data) ->
    #dbg("Data: #{JSON.stringify(data)}!")
    startTime = new Date().getTime()
    dbg("Starts loading data...")

    # Init before knockout hides related elements
    @showAsEditableInit()

    # Load periods
    Period::createFromJson(data['periods'])
    dbg("Loaded #{Period::ALL.length} periods.")

    # Load courses
    Course::createFromJson(data['courses'], data['user_courses'])
    dbg("Loaded #{Course::ALL.length} courses.")

    # Load competences
    Competence::createFromJson(data['competences'])
    dbg("Loaded #{Competence::ALL.length} competences.")

    dbg("All data loaded. Current period: #{Period::CURRENT}. Starting the autoscheduling phase.")

    # Automatically schedule unscheduled (new) courses
    schedule = new Scheduler(Course::ALL)
    schedule.scheduleUnscheduledCourses()


    # Set periods and save the 'originals'
    dbg("Setting the courses to the periods...")
    for course in Course::ALL
      # If the course was moved by the scheduler
      if schedule.moved[course.scopedId]
        course.resetOriginals()
        course.period = undefined
        course.setPeriod(schedule.schedule[course.scopedId], true)
      # Else if the course has a place to go to
      else if course.period
        period = course.period
        course.period = undefined
        course.setPeriod(period)
        course.resetOriginals()
      # Hmmh...?
      else
        dbg("WARNING: A vagabond course: #{course}!")
        course.resetOriginals()

      # Update course ordering related warnings
      course.updateReqWarnings()


    # Only because ko bindings seem unable to refer to class vars
    @periods = Period::ALL
    @courses = Course::ALL
    @competences = Competence::ALL
    # Apply ko bindings
    dbg("Applying bindings...")
    preBindTime = new Date().getTime()
    ko.applyBindings(this)
    postBindTime = new Date().getTime()


    # Update positions
    for course in Course::ALL
      course.updatePosition() if course.period

    # Flag the PlanView as ready
    PlanView::ISREADY = true

    # Initialize tooltips
    #$('div.plan div.period div.credits span').tooltip(placement: 'left')
    #$('div.plan div.course').tooltip(placement: 'bottom', delay: 1500)
    #$('div.well div.progress').tooltip(placement: 'bottom', delay: 1000)

    # Autoscroll the viewport to show the current period and the near future
    # FIXME: Don't move the viewport, but the scrollable div.
    #dbg("Autoscrolling the viewport...")
    #topOffSet = $('div.period.now').offset().top
    #$(window).scrollTop(topOffSet - 2 * @constructor.PERIOD_HEIGHT)

    # Log time used from start to bind and here
    endTime = new Date().getTime();
    dbg("Parsing & modelling the plan data took #{preBindTime - startTime} (preBind) + #{postBindTime - preBindTime} (bind) + #{endTime - postBindTime} (postBind) = #{endTime - startTime} (total) milliseconds.")


  unselectObjects: (data, event) ->
    @selectObject()


  selectObject: (object) ->

    dbg("PV::selectObject(#{object})")

    # Deselect the old object
    selectedObject = @selectedObject()

    # Call the object's setSelected handler
    if selectedObject
      selectedObject.setSelected(false)

    # Select the new object
    # NB: undefined first to avoid ko autoupdate oddness
    #dbg("Deselected [#{@selectedObjectType()}] #{selectedObject}")
    @selectedObjectType(undefined)
    @selectedObject(undefined)
    @selectedObjectType('Course') if object instanceof Course
    @selectedObjectType('Period') if object instanceof Period
    @selectedObjectType('Competence') if object instanceof Competence
    @selectedObject(object)

    # Call the object's setSelected handler
    if object
      object.setSelected(true)


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
        dbg("Course \"#{course.name}\" was changed. Pushing to be saved.")
        @coursesToSave.push(course)
        planCoursesToSave.push(course.toJson())

    if @coursesToSave.length == 0
      dbg('No plan_course was changed. No reason to put.')
      return

    dbg("A total of #{@coursesToSave.length} courses changed. Starting the put.")

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
                dbg("Course \"#{course.name}\" was successfully saved.")
                course.resetOriginals()
              else
                dbg("ERROR: Course \"#{course.name}\" was rejected by the server! Saving failed!")
                @coursesRejected.push(course)  # FIXME: Not used atm.
