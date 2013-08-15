class @Course

  VIEWMODEL: undefined

  ALL: []
  BYSCID: {}
  BYACID: {}

  constructor: (scopedId, data) ->
    @scopedId = scopedId
    @abstractId = undefined
    @code = @name = @path = ''
    @credits  = 0
    @grade    = 0
    @period   = undefined
    @skills   = []
    @prereqs  = []

    @loadJson(data || {})

    @isSelected  = ko.observable(false)
    @isPassed    = ko.observable(false)
    @isScheduled = ko.observable(false)
    @isIncluded  = ko.observable(false)
    @tooltip     = ko.observable()

    # For change checking
    @oIsIncluded = false


  createFromJson: (data) ->
    courses = []
    return courses if not data

    # We remap the ids so that everything is clear
    if data.scoped_courses
      for scopedCourseData in data.scoped_courses
        acid = scopedCourseData.abstract_course_id
        acid = scopedCourseData.abstract_course.id unless acid
        scid = scopedCourseData.id
        course = createFromPreparedData( {'scid': scid, 'acid': acid, 'scoped_course': scopedCourseData} )
        courses.push(course) if course

    if data.study_plan_courses
      for studyPlanCourseData in data.study_plan_courses
        acid = studyPlanCourseData.abstract_course_id
        acid = studyPlanCourseData.abstract_course.id unless acid
        scid = studyPlanCourseData.scoped_course_id
        scid = studyPlanCourseData.scoped_course.id unless scid
        pcid = studyPlanCourseData.id
        course = createFromPreparedData( {'scid': scid, 'acid': acid, 'pcid': pcid, 'study_plan_course': studyPlanCourseData} )
        courses.push(course) if course

    if data.user_courses
      for userCourseData in data.user_courses
        acid = userCourseData.abstract_course_id
        acid = userCourseData.abstract_course.id unless acid
        scid = userCourseData.scoped_course_id
        scid = userCourseData.scoped_course.id unless scid
        ucid = userCourseData.id
        course = createFromPreparedData( {'scid': scid, 'acid': acid, 'ucid': ucid, 'user_course': studyPlanCourseData} )
        courses.push(course) if course

    dbg.lg("Course::createFromJson(): Loaded #{courses.length} courses.")

    return courses


  createFromPreparedData: (courseData) ->
    scid = courseData.scid
    acid = courseData.acid
    if not scid
      if acid
        course = @BYACID[acid]
      if not course
        dbg.lg("Course::createFromJson(): Error: Cannot connect data to a scoped course! Refusing to load.")
        return false
    else
      dbg.lg("Course::createFromJson(): Loading with scoped course id: #{scid}...")
      course = @BYSCID[scid]
    if course
      course.loadJson(dat)
    else
      course = new Course(dat)
      @BYSCID[scid] = course
      @BYACID[acid] = course if acid  # No mixing curriculums then eh?
      @ALL.push(course)


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    #dbg.lg("C[#{@scopedId}]::loadJson( #{JSON.stringify(data)} )...")

    @scId    = data.abstract_course_id if data.abstract_course_id
    @abstractId    = data.abstract_course_id if data.abstract_course_id
    @planCourseId  = data.study_plan_course_id if data.study_plan_course_id
    @userCourseId  = data.user_course_id if data.user_course_id
    @code          = data.course_code if data.course_code
    @name          = data.localized_name if data.localized_name
    @credits       = data.credits if data.credits
    @skills        = Skill::createFromJson(data.skills) if data.skills
    @path          = data.studyplan_path if data.studyplan_path
    @prereqs       = Course::createFromJson(data.prereqs) if data.prereqs
    @grade         = data.grade if data.grade

#    @scopedCredits       = data['scoped_course']['credits']
#    @prereqIds           = data['scoped_course']['prereq_ids'] || []

    if data.period_id
      period = Period::BYID[data.period_id]
      @period = period if period

    #dbg.lg("C[#{@scopedId}]::loadJson() Finished!")
    #dbg.lg("C[#{@scopedId}]: #{@abstractId}, #{@code}, #{@name}")


  resetOriginals: ->
    @oIsIncluded = @isIncluded()


  hasChanged: ->
    return true if @oIsIncluded != @isIncluded()
    return false


  toggleInclusion: (data) ->
    dbg.lg("course::toggleInclusion(#{data})...")
    @VIEWMODEL.toggleInclusion(this)


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@scopedId}:#{@code} #{@credits} #{dbg.bals([@isSelected()])} #{@period}]"
