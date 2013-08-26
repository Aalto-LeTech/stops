#= require knockout
#= require libs/search/engine
#= require core/knockout-extensions
#= require models/core/BaseObject
#= require models/core/DbObject
#= require models/db/user
#= require models/db/curriculum
#= require models/db/period
#= require models/db/skill
#= require models/db/competence
#= require models/db/abstract_course
#= require models/db/scoped_course
#= require models/db/plan_course
#= require models/db/course_instance
#= require models/db/study_plan
#= require models/core/ModelObject
#= require models/core/ViewObject
#= require models/plan/course_model
#= require models/plan/study_plan_model
#= require models/plan/course_creation_model


if not O4.view.i18n
  throw "The i18n strings for the view have not been loaded!"




class @View extends ViewObject


  PLAN: undefined
  ENGINE: undefined
  DRAFT: undefined
  HOVERDELAY: 300
  FADEDURATION: 300
  READY: false


  constructor: ->
    super
    @lgI("view::init()...")

    #$('form').addClass('form-horizontal')
    $("form.form-search").submit( -> return false )

    BaseObject::I18N = O4.view.i18n
    BaseObject::VIEWMODEL = this

    @lgI("Parsing associations...")
    #BaseObject::DBG = true
    DbObject::parseAllAssocs()
    #BaseObject::DBG = false

    pathsContainer    = $('#paths')
    searchCoursesPath = pathsContainer.data('search-courses-path')
    studyPlanPath     = pathsContainer.data('studyplan-path')
    @lgI("db url: #{searchCoursesPath}.")

    @selected       = ko.observable()
    @sidebar        = affxd.Sidebar::get()
    @view           = ko.observable()

    @PLAN = new StudyPlanModel(studyPlanPath)
    @ENGINE = new O4.search.Engine(@, searchCoursesPath)
    @DRAFT = new CourseCreationModel()

    success = @PLAN.reload()
    if not success
      alert("#{@I18N.plan_load_error_instructions}")

    @viewTitles =
      'plan': @I18N.plan
      'changes': @I18N.changes
      'search': @I18N.search
      'create': @I18N.create


    @viewInstructions =
      'plan': @I18N.plan_instructions
      'changes': @I18N.changes_instructions
      'search': @I18N.search_instructions
      'create': @I18N.create_instructions


    @title = ko.computed =>
      return @viewTitles[@view()]

    @instructions = ko.computed =>
      return @viewInstructions[@view()]

    @showInstructions = ko.computed =>
      return true if @view() == 'plan'
      return true if @view() == 'changes'
      return true if @view() == 'search'
      return true if @view() == 'create'

    # Reconfigure the affixed sidebars height in static mode to a static value
    # instead of the default 'auto', which would cause irritable bouncing of the
    # plan div below it as the size of the former div changes.
    @sidebar.reset('staticHeight', 600)

    if @PLAN.included().length > 0
      @changeViewToPlan()
    else
      @changeViewToSearch()

    #@DBG = true
    #BaseObject::DBG = true
    #DbObject::DBG = true
    #ModelObject::DBG = true
    @READY = true

    setTimeout(
      -> $('.loader').fadeOut(1000)
      500
    )



  onInqueryChange: ->
    return
#    # Clear selection
#    @select(undefined)


  parseResults: (data) ->
    # Build objects from all the result data served and include them as
    # results

    #console.log("data:\n#{JSON.stringify(data, undefined, 2)}")

    results = []

    @lg("Constructing dbObjects...")
    dbObjects = DbObject::createFromAttrHashArrayHash(data)

    @lg("Binding associations...")
    for dbObject in dbObjects
      dbObject.bindAssocs()

    @lgI("Modeling dbObjects...")
    for dbObject in dbObjects
      if dbObject instanceof ScopedCourse
        courseModel = CourseModel::create(dbObject)
        results.push(courseModel)
        @lg(" - Modeled #{courseModel}...")

    @lgI("Modeled #{results.length} search results...")

    return results


  select: (object) ->
    @lgI("view::select(#{@selected()} -> #{object}) #{@PLAN.added().length} #{@PLAN.removed().length}...")
    return if not object instanceof CourseModel
    if object != @selected()
      oldObj = @selected()
      oldObj.isSelected(false) if oldObj
      @selected(object)
      object.isSelected(true) if object
    @lg("view::select done...")


  changeView: (view) ->
    @lgI("view::changeView(#{view})...")
    @view(view)
    $(window).scrollTop(0)


  changeViewToPlan:     -> @changeView('plan')
  changeViewToChanges:  -> @changeView('changes')
  changeViewToSearch:   -> @changeView('search')
  changeViewToCreate:   -> @changeView('create')


  saveChanges: ->
    @lgI("view::saveChanges()...")
    @PLAN.saveChanges()




jQuery ->
  view = new View()

  # Event handlers
  $(document)
    .on 'mousedown', '.course .btn', (event) ->
      # Avoid selection when pressing buttons
      event.stopPropagation()
    .on 'mousedown', '.course', (event) ->
      # Select
      object = ko.dataFor(this)
      view.select(object) if object
      event.stopPropagation()
    .on 'mousedown', '#thenavbar, #themain', (event) ->
      # Clear selection
      view.select(undefined)
    .on 'keypress', 'body', (event) ->
      # Clear selection
      if event.which == 13
        dbg.lg("Enter caught!")
        event.stopPropagation()


  dbg.lg("Applying bindings...")
  ko.applyBindings(view)


  $(window).bind 'beforeunload', =>
    return "You have unsaved changes. Leave anyway?" if view.PLAN?.anyUnsavedChanges()
