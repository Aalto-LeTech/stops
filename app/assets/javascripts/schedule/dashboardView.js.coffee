class @DashboardView

  @PERIOD_HEIGHT: 58
  @COURSE_WIDTH: 120
  @COURSE_MARGIN_X: 6
  @COURSE_MARGIN_Y: 6
  @COURSE_PADDING_Y: 3
  
  constructor: (@planUrl) ->
    @periods = []
    @periodsById = {}
    
    @courses = []
    @coursesById = {}                # scoped_course_id => Course
    @coursesByAbstractCourseId = {}  # abstract_course_id => Course
    
    @selectedCourse = ko.observable()
    

  loadPlan: () ->
    $.ajax
      url: @planUrl,
      dataType: 'json',
      success: (data) => this.parsePlan(data)


  # Loads plan from JSON data
  parsePlan: (data) ->
    # Load periods
    current_period_id = data['current_period_id']
    
    periodCounter = 0
    previousPeriod = undefined
    for raw_period in data['periods']
      period = new Period(raw_period)
      
      period.sequenceNumber = periodCounter
      period.previousPeriod = previousPeriod
      previousPeriod.nextPeriod = period if previousPeriod
      
      @periods.push(period)
      @periodsById[period.id] = period
      
      previousPeriod = period
      periodCounter++
    
    Period::currentPeriod = @periodsById[current_period_id]
    
    # Load scoped courses
    for raw_course in data['courses']
      course = new Course(raw_course)
      @courses.push(course)
      @coursesById[course.id] = course
      @coursesByAbstractCourseId[raw_course['abstract_course_id']] = course
      
      for prereq_id in raw_course['prereq_ids']
        prereq = @coursesById[prereq_id]
        course.addPrereq(prereq) if prereq
    
    # Load course instances
    for raw_instance in data['course_instances']
      course = @coursesByAbstractCourseId[raw_instance['abstract_course_id']]
      period = @periodsById[raw_instance['period_id']]
      length = raw_instance['length']
      
      continue unless course? && period?
      course_instance = new CourseInstance(raw_instance['id'], course, period, length)
      
      course.addCourseInstance(course_instance)
      
    
    ko.applyBindings(this)
    
    # Load study plan courses
    raw_plan = data['study_plan']
    for plan_course in raw_plan['study_plan_courses']
      course = @coursesById[plan_course['scoped_course_id']]
      unless course
        console.log "Unknown course #{plan_course['scoped_course_id']}"
        continue
      
      period_id = plan_course['period_id']
      if period_id
        period = @periodsById[period_id] 
      
        if period
          course.setPeriod(period)


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
