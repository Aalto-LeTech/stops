#= require knockout
#= require libs/search/engine
#= require core/knockout-extensions
#= require core/delayed
#= require models/plan/plan
#= require models/plan/course


class @View

  HOVERDELAY: 300
  FADEDURATION: 300

  constructor: () ->
    dbg.lg("Starting the search engine!")
    pathsContainer = $('#paths')
    searchCoursesPath = pathsContainer.data('search-courses-path')
    studyplanPath = pathsContainer.data('studyplan-path')
    dbg.lg("db url: #{searchCoursesPath}.")

    @eWell      = $('#theleft .well')
    @doShowWell = ko.observable(true)
    @selected   = ko.observable()
    @sidebar    = affxd.Sidebar::get()
    @engine     = new O4.search.Engine(@, searchCoursesPath)
    @selector   = new DelayedCaller(@HOVERDELAY, (object) => @select(object))
    @plan       = new Plan(studyplanPath)

    @doShowWell.subscribe (newValue) =>
      if newValue
        @eWell.fadeIn(@FADEDURATION)
      else
        @eWell.fadeOut(@FADEDURATION)


  onInqueryChange: ->
    # Clear selection
    @selector.immediate()


  parseResults: (data) ->
    results = []
    # Build objects from all the result data served and include them as
    # results
    if data.scoped_courses?
      results = Course::createFromJson(data.scoped_courses)
    n = 0

    # Additional binding
    for result in results
      course = @plan.coursesByScopedId[result.id]
      continue if not course

      result.period = course.period
      result.grade  = course.grade
      result.isIncluded(true)
      result.isPassed(course.grade > 0)
      n += 1
    dbg.lg("Found #{n} matches!")
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




jQuery ->
  view = new View()

  # Event handlers
  $(document)
    .on 'mouseenter', '.result', (event) ->
      #dbg.lg("mouseenter .results.")
      object = ko.dataFor(this)
      event.stopPropagation() if view.hoveringOn(object)
    .on 'mouseleave', '.result', (event) ->
      #dbg.lg("mouseleave .results.")
      object = ko.dataFor(this)
      event.stopPropagation() if view.hoveringOn(object, false)
    .on 'mousedown', '#themain', (event) ->
      #dbg.lg("mousedown #themain.")
      # Clear selection
      view.selector.delayed(undefined)
      #dbg.lg("doShowWell: #{view.doShowWell()}")


  dbg.lg("Applying bindings on the view...")
  ko.applyBindings(view, $('#theleft').get(0))

  dbg.lg("Applying bindings on the engine...")
  ko.applyBindings(view.engine, $('#themain').get(0))
