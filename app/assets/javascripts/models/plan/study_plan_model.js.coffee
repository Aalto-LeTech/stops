class @StudyPlanModel extends ModelObject
  # Nice and simple


  # Constructor
  constructor: (dataPath) ->
    super()
    @dataPath        = dataPath
    @originalsHash   = {}
    @included        = ko.observableArray()
    @added           = ko.observableArray()
    @removed         = ko.observableArray()

    @changed = ko.computed =>
      return @added().concat(@removed())

    @hasUnsavedChanges = ko.computed =>
      return @changed().length > 0


  # Create (load) method
  reload: ->
    @lgI("Loading the plan and its related data from the database...")
    # Load and instantiate the plan and all related objects
    DbObject::createFromDataPath(@dataPath, @loadErrorHandler)

    if StudyPlan::ALL.length == 0
      dbg.lgE("No studyplan available!")
      #@loadErrorHandler()
      return false
    else if StudyPlan::ALL.length > 1
      dbg.lgE("Multiple studyplans available!")
      #@loadErrorHandler()
      return false

    @lg("Loaded the plan successfully!")
    @studyplan = StudyPlan::ALL[0]

    if not @studyplan
      dbg.lgE("Trying to create a StudyPlanModel with no StudyPlan!")
      return false

    @lg("Binding associations...")
    DbObject::bindAllAssocs()

    @lg("Modeling plan courses...")
    for planCourse in @studyplan.planCourses
      courseModel = CourseModel::create(planCourse)
      @included.push(courseModel)
      @originalsHash[courseModel.boId] = courseModel

    if @included().length == 0
      dbg.lgW("The a StudyPlan has no courses!")

    @lgI("Instantiated #{@included().length} course models to the plan.")
    return true


  # Error handler
  loadErrorHandler: (data) ->
    dbg.lgE("Loading the plan failed!")
    #alert("#{@I18N.plan_load_error_instructions}")


  # Renders the object into a string for debugging purposes
  toString: ->
    return "#{super()}:{}"


  # Adds a course to the plan model and tracks changes
  add: (course) ->
    @lg("plan::add()...")
    @included.push(course)
    @removed().removeIf(course)
    @removed.valueHasMutated()
    @added.push(course) if not @originalsHash[course.boId]


  # Removes a course from the plan model and tracks changes
  remove: (course) ->
    @lg("plan::remove()...")
    @included().removeIf(course)
    @included.valueHasMutated()
    @removed.push(course) if @originalsHash[course.boId]
    @added().removeIf(course)
    @added.valueHasMutated()


  # Returns true if there is any nonsaved data
  anyUnsavedChanges: ->
    # Return whether any changes were made
    return @hasUnsavedChanges()


  # Saves the changes made to the plan by sending to the server data in the
  # following form:
  # {
  #   "scoped_course_ids_to_add": [71, 35, 56...],
  #   "plan_course_ids_to_remove": [12, 435, 3...]
  # }
  saveChanges: ->
    # Check if any changes should be saved
    if not @anyUnsavedChanges()
      dbg.lg('No changes. No reason to put.')
      return

    dbg.lg('Compiling data to push...')

    @scopedCourseIdsToAdd = []
    for course in @added()
      @scopedCourseIdsToAdd.push(course.scopedCourse.id) if course.scopedCourse?.id

    @planCourseIdsToRemove = []
    for course in @removed()
      @planCourseIdsToRemove.push(course.planCourse.id) if course.planCourse?.id

    json =
      'scoped_course_ids_to_add': JSON.stringify(@scopedCourseIdsToAdd)
      'plan_course_ids_to_remove': JSON.stringify(@planCourseIdsToRemove)

    la = @scopedCourseIdsToAdd.length
    lr = @planCourseIdsToRemove.length

    dbg.lg("A total of #{la + lr} changes (#{la} added, #{lr} removed). Starting the put.")

    $.ajax
      url: @dataPath,
      type: 'put',
      dataType: 'json',
      async: false,
      data: { 'json': json },
      success: (data) =>
        if data['status'] == 'ok'
          feedback = data['feedback']
          if feedback
            for scopedCourseId in @scopedCourseIdsToAdd
              course = CourseModel::BYSCID[scopedCourseId]
              planCourseHash = feedback['scoped_course_ids_to_add'][scopedCourseId]
              if planCourseHash
                dbg.lg("Course \"#{course.name()}\" was successfully added.")
                @added().removeIf(course)
                @added.valueHasMutated()
                [dbPlanCourse, isOk] = PlanCourse::createFromAttrHash(planCourseHash)
                if not isOk
                  dbg.lgE("Creating the dbPlanCourse failed (hash: #{JSON.stringify(planCourseHash, undefined, 2)})!")
                else
                  dbg.lgE("DbPlanCourse created (hash: #{JSON.stringify(planCourseHash, undefined, 2)})!")
                  dbPlanCourse.bindAssocs()
                  @originalsHash[course.boId] = CourseModel::create(dbPlanCourse)
              else
                dbg.lg("ERROR: The server refused to add course \"#{course.name()}\"!")
            for planCourseId in @planCourseIdsToRemove
              course = CourseModel::BYPCID[planCourseId]
              if feedback['plan_course_ids_to_remove'][planCourseId]
                dbg.lg("Course \"#{course.name()}\" was successfully removed.")
                @removed().removeIf(course)
                @removed.valueHasMutated()
                delete @originalsHash[course.boId]
              else
                dbg.lg("ERROR: The server refused to remove course \"#{course.name()}\"!")
          else
            dbg.lg("ERROR: No feedback returned!")
        else
          dbg.lg("ERROR: Put on server failed!")
