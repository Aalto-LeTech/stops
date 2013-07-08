class @DashboardView

  constructor: (@planUrl) ->
    @translations              = {}                    # text translations for the view

    @periods                   = []
    @periodsById               = {}

    @currentPeriod             = ko.observable()

    @courses                   = []
    @coursesById               = {}                    # scoped_course_id => Course
    @coursesByAbstractId       = {}                    # abstract_course_id => Course

    @currentCoursesTable       = new CourseTable( 'cnx' )
    @upcomingCoursesTable      = new CourseTable( 'cnx' )
    @scheduledCoursesTable     = new CourseTable( 'cnxp' )
    @unscheduledCoursesTable   = new CourseTable( 'cnx' )
    @passedCoursesTable        = new CourseTable( 'cnxPg' )

    @selectedCourse            = ko.observable()

  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.parsePlan(data)


  # Loads plan from JSON data
  parsePlan: (data) ->
    # Load translations
    @translations = data['translations']
    CourseTable::readTranslations( @translations )
    @currentCoursesTable.heading      = @translations['current']
    @upcomingCoursesTable.heading     = @translations['upcoming']
    @scheduledCoursesTable.heading    = @translations['scheduled']
    @unscheduledCoursesTable.heading  = @translations['unscheduled']
    @passedCoursesTable.heading       = @translations['passed']

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

    Period::currentPeriod = @periodsById[currentPeriodId]
    @currentPeriod( Period::currentPeriod )

    # Load scoped courses
    for rawCourse in data['courses']
      course = new Course(rawCourse)
      @courses.push(course)
      @coursesById[course.id] = course
      @coursesByAbstractId[rawCourse['abstract_course_id']] = course

      for prereqId in rawCourse['prereq_ids']
        prereq = @coursesById[prereqId]
        course.addPrereq(prereq) if prereq

    # Load course instances
    for rawCourse in data['course_instances']
      abstractId = rawCourse['abstract_course_id']
      course = @coursesByAbstractId[abstractId]
      period = @periodsById[rawCourse['period_id']]
      length = rawCourse['length']

      continue unless course? && period?

      instance = new CourseInstance(rawCourse['id'], course, period, length)

      course.addCourseInstance(instance)

    # Load study plan courses
    for rawCourse in data['study_plan']['study_plan_courses']
      course = @coursesById[rawCourse['scoped_course_id']]
      unless course
        console.log "Unknown course #{rawCourse['scoped_course_id']}"
        continue

      periodId = rawCourse['period_id']
      if periodId
        period = @periodsById[periodId]

        if period
          course.setPeriod(period)

          @scheduledCoursesTable.push( course )

          if period == Period::currentPeriod
            @currentCoursesTable.push( course )
          else if period == Period::currentPeriod.nextPeriod
            @upcomingCoursesTable.push( course )

        else
          @unscheduledCoursesTable.push( course )

    # Load passed courses
    for rawCourse in data['passed_courses']
      course = @coursesByAbstractId[rawCourse['abstract_course_id']]
      unless course
        console.log "Unknown course #{rawCourse['abstract_course_id']}"
        continue

      course.setAsPassed(rawCourse['course_instance_id'], rawCourse['grade'])

      @passedCoursesTable.push( course )

    # Compile data for html tables
    CourseTable::updateAll()

    # Show data by applying (rendering) Knockout bindings
    ko.applyBindings(this)


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
