# Check that i18n strings have been loaded before this file
if not O4.schedule.i18n
  throw "plan view i18n strings have not been loaded!"

class @PlanView

  @PERIOD_HEIGHT: 58
  @COURSE_WIDTH: 120
  @COURSE_MARGIN_X: 6
  @COURSE_MARGIN_Y: 6
  @COURSE_PADDING_Y: 3
  ISREADY: false

  constructor: (@planUrl) ->
    @selectedObject = ko.observable()
    @selectedObjectType = ko.observable()

    @showAsEditable = false
    #@showAsEditable = ko.observable(false)

    # List of courses to be saved and rejected when tried to save.
    # Both are used and managed at @save()
    @coursesToSave = []
    @coursesRejected = []


  showAsEditableInit: ->
    #dbg.lg("showAsEditableInit()!")
    @showAsEditable = false
    $('#credits #in, #grade #in, #length #in').hide()


  doShowAsEditable: ->
    if not @showAsEditable
      @showAsEditable = true
      #dbg.lg("showAsEditable -> #{@showAsEditable}!")
      $('#credits #out, #grade #out, #length #out').hide()
      $('#credits #in, #grade #in, #length #in').show()


  noShowAsEditable: ->
    if @showAsEditable
      @showAsEditable = false
      #dbg.lg("showAsEditable -> #{@showAsEditable}!")
      $('#credits #in, #grade #in, #length #in').hide()
      $('#credits #out, #grade #out, #length #out').show()


  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.loadJson(data)


  # Loads the plan from JSON data
  loadJson: (data) ->
    #dbg.lg("Data: #{JSON.stringify(data)}!")
    startTime = new Date().getTime()
    dbg.lg("Starts loading data...")

    # Init before knockout hides related elements
    @showAsEditableInit()

    # Load periods
    Period::createFromJson(data['periods'])
    dbg.lg("Loaded #{Period::ALL.length} periods.")

    # Load courses
    Course::createFromJson(data['courses'], data['user_courses'])
    dbg.lg("Loaded #{Course::ALL.length} courses.")

    # Load competences
    Competence::createFromJson(data['competences'])
    dbg.lg("Loaded #{Competence::ALL.length} competences.")

    dbg.lg("All data loaded. Current period: #{Period::CURRENT}. Starting the autoscheduling phase.")

    # Automatically schedule unscheduled (new) courses
    schedule = new Scheduler(Course::ALL)
    schedule.scheduleUnscheduledCourses()


    # Set periods and save the 'originals'
    dbg.lg("Setting the courses to the periods...")
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
        dbg.lg("WARNING: A vagabond course: #{course}!")
        course.resetOriginals()

      # Update course ordering related warnings
      course.updateReqWarnings()


    # Only because ko bindings seem unable to refer to class vars
    @periods = Period::ALL
    @courses = Course::ALL
    @competences = Competence::ALL
    # Apply ko bindings
    dbg.lg("Applying bindings...")
    preBindTime = new Date().getTime()
    ko.applyBindings(this)
    postBindTime = new Date().getTime()

    # Update positions
    for course in Course::ALL
      course.updatePosition() if course.period

    # Flag the PlanView as ready
    PlanView::ISREADY = true

    # Set the initial viewport at the current period
    @selectObject(Period::CURRENT)

    # Initialize tooltips
    #$('div#plan-container div.period div.credits span').tooltip(placement: 'left')
    #$('div#plan-container div.course').tooltip(placement: 'bottom', delay: 1500)
    #$('div.well div.progress').tooltip(placement: 'bottom', delay: 1000)

    # Autoscroll the viewport to show the current period and the near future
    dbg.lg("Autoscrolling the viewport...")
    topOffSet = $('div.period.now').offset().top
    $(window).scrollTop(topOffSet - 2 * @constructor.PERIOD_HEIGHT)

    # Reconfigure the affixed sidebars height in static mode to a static value
    # instead of the default 'auto', which would cause irritable bouncing of the
    # plan div below it as the size of the former div changes.
    # The 'update' method is also called so that it can realize that the size of
    # the div it is to 'side' has changed as periods have been injected into it.
    affixedSidebar = affxd.Sidebar::get()
    affixedSidebar.staticHeight = 600
    affixedSidebar.update()

    # Log time used from start to bind and here
    endTime = new Date().getTime();
    dbg.lg("Parsing & modelling the plan data took #{preBindTime - startTime} (preBind) + #{postBindTime - preBindTime} (bind) + #{endTime - postBindTime} (postBind) = #{endTime - startTime} (total) milliseconds.")


  unselectObjects: (data, event) ->
    @selectObject()


  selectObject: (object) ->

    #dbg.lg("PV::selectObject(#{object})")

    # Deselect the old object
    selectedObject = @selectedObject()

    # Call the object's setSelected handler
    if selectedObject
      selectedObject.setSelected(false)

    # Select the new object
    # NB: undefined first to avoid ko autoupdate oddness
    #dbg.lg("Deselected [#{@selectedObjectType()}] #{selectedObject}")
    @selectedObjectType(undefined)
    @selectedObject(undefined)
    @selectedObjectType('Course') if object instanceof Course
    @selectedObjectType('Period') if object instanceof Period
    @selectedObjectType('Competence') if object instanceof Competence
    @selectedObject(object)

    # Call the object's setSelected handler
    if object
      object.setSelected(true)

    # Scroll the scrollbar in order to have the selected object visible.
    # Important when using the keyboard.
    if @selectedObjectType() in ['Course', 'Period']
      # Load the viewports DOM data; using an approximation for scrollbar height
      viewPortTop = $(window).scrollTop()
      viewPortHeight = $(window).height()
      viewPortBottom = viewPortTop + viewPortHeight
      objectContainerTop = $('#themain').offset().top
      if @selectedObjectType() == 'Course'
        objectHeight = object.position().height
      else
        objectHeight = PlanView.PERIOD_HEIGHT
      # The 0.25's are added in order to not be too strict
      objectTop = object.position().y + objectContainerTop
      objectBottom = objectTop + objectHeight
      objectTopLimit = objectTop + objectHeight * 0.25
      objectBottomLimit = objectTop + objectHeight * 0.75

      dbg.lg("topOffSet: #{objectTop} - #{objectBottom} vs #{viewPortTop} - #{viewPortBottom}.")

      # If 3/4ths of the object cannot be seen, we recenter the viewport
      if objectBottomLimit > viewPortBottom
        newViewPortTop = (objectBottom + objectTop) / 2 - viewPortHeight / 2
      else if objectTopLimit < viewPortTop
        newViewPortTop = (objectBottom + objectTop) / 2 - viewPortHeight / 2

      $(window).scrollTop(newViewPortTop)


  # Reset the coursesToSave array according to changes made since last save
  updateCoursesToSave: ->
    @coursesToSave = []
    for course in Course::ALL
      if course.hasChanged()
        dbg.lg("Course \"#{course.name}\" was changed.")
        @coursesToSave.push(course)

    if @coursesToSave.length == 0
      dbg.lg('No essential changes on any course.')


  # Returns true if there is any nonsaved data
  anyUnsavedChanges: ->
    # Update coursesToSave according to made changes
    @updateCoursesToSave()
    # Check if any changes were made
    return @coursesToSave.length > 0


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

    # Check if any changes should be saved
    if not @anyUnsavedChanges()
      dbg.lg('No unsaved data. No reason to put.')
      return

    # Load the data
    planCoursesToSave = []  # Array for course JSON representations for sending
    for course in @coursesToSave
      dbg.lg("Pushing \"#{course.name}\" to be saved.")
      planCoursesToSave.push(course.toJson())

    dbg.lg("A total of #{@coursesToSave.length} courses changed. Starting the put.")

    # For informing the user of potential unaccepted alterations / db failures
    @coursesRejected = []

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
                dbg.lg("Course \"#{course.name}\" was successfully saved.")
                course.resetOriginals()
              else
                dbg.lg("ERROR: Course \"#{course.name}\" was rejected by the server! Saving failed!")
                @coursesRejected.push(course)  # FIXME: Not used atm.
