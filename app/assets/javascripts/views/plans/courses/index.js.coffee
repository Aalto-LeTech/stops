#= require knockout
#= require libs/search/engine
#= require core/knockout-extensions
#= require core/delayed
#= require models/plan/period
#= require models/plan/skill
#= require models/plan/course
#= require models/plan/plan


if not O4.view.i18n
  throw "The i18n strings for the view have not been loaded!"


#class @Action

#  init: (action, plan, course) ->
#    action.plan = plan
#    action.course = course
#    action.safe = {}
#    action.isExecuted = false
#    action.execute()


#class @AddAction

#  constructor: (plan, course) ->
#    @name = "#{O4.view.i18n.added}"
#    @spec = "#{course.name}"
#    Action::init(@, plan, course)

#  execute: ->
#    existingCourse = @plan.coursesById[@course.id]
#    if not existingCourse
#      @plan.courses.push(@course)
#      @plan.coursesById[@course.id] = @course
#    @safe.isIncluded = @course.isIncluded()
#    @course.isIncluded(true)
#    @isExecuted = true

#  cancel: ->
#    @plan.courses.splice(@plan.courses.indexOf(@course), 1)
#    @plan.coursesById[@course.id] = undefined
#    @course.isIncluded(@safe.isIncluded)
#    @isExecuted = false


#class @RemoveAction

#  constructor: (plan, course) ->
#    @name = "#{O4.view.i18n.removed}"
#    @spec = "#{course.name}"
#    Action::init(@, plan, course)

#  execute: ->
#    existingCourse = @plan.coursesById[@course.id]
#    if existingCourse
#      @plan.courses.splice(@plan.courses.indexOf(@course), 1)
#      @plan.coursesById[@course.id] = undefined
#    @safe.period = @course.period
#    @course.period = undefined
#    #@safe.grade = @course.grade
#    #@course.grade = 0 # flag for destr?
#    @safe.isIncluded = @course.isIncluded()
#    @course.isIncluded(false)
#    @isExecuted = true

#  cancel: ->
#    @plan.courses.push(@course)
#    @plan.coursesById[@course.id] = @course
#    @course.period = @safe.period
#    #grade
#    @course.isIncluded(@safe.isIncluded)
#    @isExecuted = false


class @View

  HOVERDELAY: 300
  FADEDURATION: 300

  constructor: () ->
    dbg.lg("Starting the search engine!")
    pathsContainer = $('#paths')
    searchCoursesPath = pathsContainer.data('search-courses-path')
    studyplanPath = pathsContainer.data('studyplan-path')
    dbg.lg("db url: #{searchCoursesPath}.")

    @i18n           = O4.view.i18n
    @eWell          = $('#theleft .well')
    @doShowWell     = ko.observable(true)
    @selected       = ko.observable()
    @sidebar        = affxd.Sidebar::get()
    @engine         = new O4.search.Engine(@, searchCoursesPath)
    @selector       = new DelayedCaller(@HOVERDELAY, (object) => @select(object))
    @plan           = new Plan(studyplanPath)

    @view           = ko.observable()

    @viewTitles = {
      'courses': @i18n.courses
      'search': @i18n.search
      'changes': @i18n.changes
    }

    @viewInstructions = {
      'courses': @i18n.courses_instructions
      'search': @i18n.search_instructions
      'changes': @i18n.changes_instructions
    }

    @title = ko.computed =>
      return @viewTitles[@view()]

    @instructions = ko.computed =>
      return @viewInstructions[@view()]

    @showInstructions = ko.computed =>
      return true if @view() == 'courses'
      return true if @view() == 'search' and @engine.results().length == 0
      return true if @view() == 'changes'

    @infoMsg = ko.computed =>
      if @view() == 'search'
        infoMsg = @engine.infoMsg()
      else
        infoMsg = ''
      return infoMsg

    @courses = ko.computed =>
      if @view() == 'courses'
        courses = []
      else if @view() == 'search'
        courses = @engine.results()
      else if @view() == 'changes'
        changed = []
        if @plan.anyUnsavedChanges()
          for course in @plan.scopedCoursesToAdd
            changed.push(Course::BYSCID[course.id])
          for course in @plan.planCoursesToRemove
            changed.push(Course::BYPLANCOURSEID[course.id])
      else
        courses = []
      return courses

    Plan::VIEWMODEL = this
    Course::VIEWMODEL = this

    @doShowWell.subscribe (newValue) =>
      if newValue
        @eWell.fadeIn(@FADEDURATION)
      else
        @eWell.fadeOut(@FADEDURATION)

    # Reconfigure the affixed sidebars height in static mode to a static value
    # instead of the default 'auto', which would cause irritable bouncing of the
    # plan div below it as the size of the former div changes.
    @sidebar.staticHeight = 600
    @sidebar.update()

    @setViewCourses()


  # Method called after the plan has been loaded
  planLoaded: ->
    for course in Course::ALL
      course.resetOriginals()


  updateTooltip: (course) ->
    if course.isIncluded()
      if course.period
        if course.grade > 0
          tooltip = "#{@i18n.is_passed_with_grade} #{course.grade} #{@i18n.in_period} #{course.period.name}."
        else
          tooltip = "#{@i18n.is_scheduled_to_period} #{course.period.name}."
      else if course.grade > 0
        tooltip = "#{@i18n.is_passed_with_grade} #{course.grade}#{@i18n.but_not_scheduled}"
      else
        tooltip = "#{@i18n.is_included_in_the_plan}"
    else
      if course.grade > 0
        tooltip = "#{@i18n.is_passed_with_grade} #{course.grade}#{@i18n.but_not_included_into_the_plan}"
      else
        tooltip = "#{@i18n.is_not_included_in_the_plan}"
    course.tooltip(tooltip)


  onInqueryChange: ->
    # Clear selection
    @selector.immediate()


  parseResults: (data) ->

    # Build objects from all the result data served and include them as
    # results
    results = []
    results = Course::createFromJson(data)

    # Update tooltip
    for result in results
      @updateTooltip(result)

    return results


  hoveringOn: (object, state=true) ->
    if object
      if object != @selected()
        if state
          @selector.delayed(object)
        else
          @selector.cancel()
      return true
    else
      dbg.lg("ERR: No object found (#{object}).")
      @selector.delayed(undefined)
      return false


  select: (object) ->
    #dbg.lg("view::select(#{@selected()} -> #{object})...")
    if object != @selected()
      oldObj = @selected()
      oldObj.isSelected(false) if oldObj
      if @doShowWell()
        @doShowWell(false)
        @selector.delayed(object, @FADEDURATION)
      else
        @selected(object)
        object.isSelected(true) if object
        @doShowWell(true)
    #dbg.lg("view::select done...")


  toggleInclusion: (course) ->
    dbg.lg("view::toggleInclusion(#{course})...")
    @plan.toggleInclusion(course)
    @updateTooltip(course)


  setView: (view) ->
    dbg.lg("view::setView(#{view})...")
    @view(view)

  setViewCourses: ->
    @setView('courses')
  setViewSearch: ->
    @setView('search')
  setViewChanges: ->
    @setView('changes')


  saveChanges: ->
    dbg.lg("view::saveChanges()...")
    @plan.save()




jQuery ->
  view = new View()

  # Event handlers
  $(document)
    .on 'mouseenter', '.course', (event) ->
      object = ko.dataFor(this)
      event.stopPropagation() if view.hoveringOn(object)
    .on 'mouseleave', '.course', (event) ->
      object = ko.dataFor(this)
      event.stopPropagation() if view.hoveringOn(object, false)
    .on 'mousedown', '.course', (event) ->
      event.stopPropagation()
    .on 'mousedown', '#themain', (event) ->
      #dbg.lg("mousedown #themain.")
      # Clear selection
      view.selector.delayed(undefined)
      #dbg.lg("doShowWell: #{view.doShowWell()}")


  dbg.lg("Applying bindings...")
  ko.applyBindings(view)


#  $(window).bind 'beforeunload', =>
#    return "You have unsaved changes on #{view.plan.coursesToSave.length} course(s). Leave anyway?" if view.plan?.anyUnsavedChanges()
