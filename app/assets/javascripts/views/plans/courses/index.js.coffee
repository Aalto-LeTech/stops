#= require knockout
#= require libs/search/engine
#= require core/knockout-extensions

class @DelayedCaller

  constructor: (delay, call) ->
    dbg.lg("DelayedCaller::constructor()...")
    @delay    = delay
    @call     = call
    @tstamp   = undefined

  immediate: (object) ->
    @tstamp = undefined
    @call(object)

  delayed: (object, delay=@delay) ->
    tstamp = new Date().getTime()
    @tstamp = tstamp
    setTimeout(
      =>
        if @tstamp == tstamp
          @call(object)
      ,
      delay
    )

  cancel: ->
    @tstamp = undefined


class @View

  HOVERDELAY: 800
  FADEDURATION: 300

  constructor: () ->
    dbg.lg("Starting the search engine!")
    resultsContainer = $('.search-results-container')
    serverPath = resultsContainer.data('courses-path')
    dbg.lg("db url: #{serverPath}.")

    @eWell      = $('#theleft .well')
    @doShowWell = ko.observable(true)
    @selected   = ko.observable()
    @sidebar    = affxd.Sidebar::get()
    @engine     = new O4.search.Engine(@, serverPath)
    @selector   = new DelayedCaller(@HOVERDELAY, (object) => @select(object))

    @doShowWell.subscribe (newValue) =>
      if newValue
        @eWell.fadeIn(@FADEDURATION)
      else
        @eWell.fadeOut(@FADEDURATION)


  onInqueryChange: ->
    # Clear selection
    @selector.immediate()


  onResultsChange: ->
    # Clear selection
    @selector.immediate()

    # The 'update' method must be called so that it can readjust for the
    # changed size of the div it is to 'side'.
    @sidebar.update()


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
    dbg.lg("view::select(#{@selected()} -> #{object})...")
    if object != @selected()
      if @doShowWell()
        @doShowWell(false)
        @selector.delayed(object, @FADEDURATION)
      else
        @selected(object)
        @doShowWell(true)
    dbg.lg("view::select done...")




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
