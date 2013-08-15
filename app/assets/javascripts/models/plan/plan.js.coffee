class @Plan

  VIEWMODEL: undefined

  constructor: (path) ->

    return if not path?

    @path = path
    @courses = []
    @coursesByScopedId = {}
    @reload()

    # List of courses to be saved and rejected when tried to save.
    @scopedCoursesToAdd = []
    @studyPlanCoursesToRemove = []
    @hasUnsavedChanges = false


  reload: ->
    $.ajax
      type: "GET",
      url: @path,
      data: { bundle: 'schedule' },
      #data: { bundle: 'courses_with_ids_grades_and_periods' },
      context: this,
      dataType: 'json',
      success: @reloadSuccess,
      error: @reloadError,
      async: true


  reloadSuccess: (data) ->

    failed = false

    if not data
      dbg.lg("ERR: No data!")
      failed = true

    if not data.periods?
      dbg.lg("ERR: No period data!")
      failed = true

    if not data.study_plan_courses?
      dbg.lg("ERR: No study plan course data!")
      failed = true

    if not data.user_courses?
      dbg.lg("ERR: No user course data!")
      failed = true

    #dbg.lg("data: #{JSON.stringify(data)}!")
    return if failed

    # Reinitialize data
    @courses = []
    @coursesByScopedId = {}

    # Load periods in plan
    Period::createFromJson(data.periods)

    # Load courses in plan
    for course in Course::createFromJson(data)
      @courses.push(course)
      @coursesByScopedId[course.scopedId] = course
      course.isIncluded(true)
    dbg.lg("Loaded #{@courses.length} study plan courses.")

    ## Load grades
    #for grade in data.grades
    #  course = Course::BYACID[grade.abstract_course_id]
    #  if course
    #    course.grade = grade.grade
    #  else
    #    dbg.lg("Unknown course encountered: AID: #{grade.abstract_course_id}!")
    #dbg.lg("Loaded #{data.grades.length} grades.")

    @VIEWMODEL.planLoaded()


  reloadError: (data) ->
    alert('Loading studyplan data failed!')


  # Add the course to the plan
  add: (course) ->
    dbg.lg("plan::add( #{course.name} )...")
    return if course.isIncluded()
    existingCourse = @coursesByScopedId[course.scopedId]
    if not existingCourse
      @courses.push(course)
      @coursesByScopedId[course.scopedId] = course
    course.isIncluded(true)


  # Remove the course from the plan
  remove: (course) ->
    dbg.lg("plan::remove( #{course.name} )...")
    return if not course.isIncluded()
    existingCourse = @coursesByScopedId[course.scopedId]
    if existingCourse
      @courses.splice(@courses.indexOf(course), 1)
      @coursesByScopedId[course.scopedId] = undefined
    #course.period = undefined
    #course.grade = 0 # flag for destr?
    course.isIncluded(false)


  # Adds or removes a course from the plan
  toggleInclusion: (object) ->
    dbg.lg("plan::toggleInclusion( #{object.name} )...")
    if object.isIncluded()
      @remove(object)
    else
      @add(object)


  # Reset the coursesToSave array according to changes made since last save
  detectChanges: ->
    @scopedCoursesToAdd = []
    @studyPlanCoursesToRemove = []
    for course in Course::ALL
      if course.scopedId and course.isIncluded() and course.oIsIncluded == false
        dbg.lg("Pushing \"#{course.name}\" (#{course.scopedId}) for adding.")
        @scopedCoursesToAdd.push( { 'id': course.scopedId } )
      else if course.planCourseId and not course.isIncluded() and course.oIsIncluded
        dbg.lg("Pushing \"#{course.name}\" (#{course.planCourseId}) for removal.")
        @studyPlanCoursesToRemove.push( { 'id': course.planCourseId } )

    @hasUnsavedChanges =
      @scopedCoursesToAdd.length > 0 or
      @studyPlanCoursesToRemove.length > 0

    if not @hasUnsavedChanges
      dbg.lg('No course added nor removed.')


  # Returns true if there is any nonsaved data
  anyUnsavedChanges: ->
    # Detect changes made changes
    @detectChanges()
    # Return whether any changes were made
    return @hasUnsavedChanges


  # Saves the changes made to the plan by sending to the server data in the
  # following form:
  # {
  #   "scoped_courses_to_add": [
  #     {"scoped_course_id": 71},
  #     {"scoped_course_id": 35},
  #     ...
  #   ]
  #   "study_plan_courses_to_remove": [
  #     {"study_plan_course_id": 10},
  #     {"study_plan_course_id": 29},
  #     ...
  #   ]
  # }
  save: ->
    # Check if any changes should be saved
    if not @anyUnsavedChanges()
      dbg.lg('No changes. No reason to put.')
      return

    json = {
      'scoped_courses_to_add': JSON.stringify(@scopedCoursesToAdd),
      'study_plan_courses_to_remove': JSON.stringify(@studyPlanCoursesToRemove)
    }

    la = @scopedCoursesToAdd.length
    lr = @studyPlanCoursesToRemove.length

    dbg.lg("A total of #{la + lr} changes (#{la} added, #{lr} removed). Starting the put.")

    $.ajax
      url: @planUrl,
      type: 'put',
      dataType: 'json',
      async: false,
      data: { 'json': json },
      success: (data) =>
        if data['status'] == 'ok'
          feedback = data['feedback']
          if feedback
            for course in @coursesToSave
              if course.isIncluded()
                if feedback['scoped_courses_to_add'][course.scopedId]
                  dbg.lg("Course \"#{course.name}\" was successfully added.")
                  course.resetOriginals()
                else
                  dbg.lg("ERROR: The server refused to add course \"#{course.name}\"!")
              else
                if feedback['study_plan_courses_to_remove'][course.planCourseId]
                  dbg.lg("Course \"#{course.name}\" was successfully removed.")
                  course.resetOriginals()
                else
                  dbg.lg("ERROR: The server refused to add course \"#{course.name}\"!")
          else
            dbg.lg("ERROR: No feedback returned!")
        else
          dbg.lg("ERROR: Put on server failed!")
