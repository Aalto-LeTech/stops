class @ScopedCourse


  VIEWMODEL: undefined

  ALL: []
  BYID: {}


  # Creates and or updates models with the given data
  createFromHashes: (hashes) ->

    dbg.lg("ScopedCourse::createFromHashes()...")

    courses = []
    return courses if not hashes

    for hash in hashes
      if hash.id
        course = @BYID[hash.id]
        if course
          course.loadJson(dat)
        else
          course = new ScopedCourse(hash)
      else
        dbg.lg("ScopedCourse::createFromHashes(): Invalid hash! No id (hash: #{JSON.stringify(hash)}).")

    dbg.lg("ScopedCourse::createFromHashes(): Loaded #{courses.length} courses.")

    return courses


  # Creates the model
  constructor: (data) ->

    @loadJson(data || {})


  # Loads the models core attributes
  loadJson: (hash) ->

    @id            = hash.id
    @code          = hash.code if data.code

    if @id
      @BYID[@id] = this
      @ALL.push(this)
    else
      dbg.lg("ScopedCourse::loadJson(): ERROR: No id!")


  # Resets original values for change detection
  resetOriginals: ->

    @oCode = @code


  # Returns whether the models attributes have been changed
  hasChanged: ->

    return true if @oCode != @code
    return false


  # Renders the object into a string for debugging purposes
  toString: ->

    "AC[#{@id}:#{@code}]"

class @ScopedCourse

  VIEWMODEL: undefined

  ALL: []
  BYID: {}

  constructor: (data) ->
    @id = id
    @acid = undefined
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

    if data.plan_courses
      for planCourseData in data.plan_courses
        acid = planCourseData.abstract_course_id
        acid = planCourseData.abstract_course.id unless acid
        scid = planCourseData.scoped_course_id
        scid = planCourseData.scoped_course.id unless scid
        pcid = planCourseData.id
        course = createFromPreparedData( {'scid': scid, 'acid': acid, 'pcid': pcid, 'plan_course': planCourseData} )
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
      course = @BYID[scid]
    if course
      course.loadJson(dat)
    else
      course = new Course(dat)
      @BYID[scid] = course
      @BYACID[acid] = course if acid  # No mixing curriculums then eh?
      @ALL.push(course)


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    #dbg.lg("C[#{@id}]::loadJson( #{JSON.stringify(data)} )...")

    @scId    = data.abstract_course_id if data.abstract_course_id
    @acid    = data.abstract_course_id if data.abstract_course_id
    @planCourseId  = data.plan_course_id if data.plan_course_id
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

    #dbg.lg("C[#{@id}]::loadJson() Finished!")
    #dbg.lg("C[#{@id}]: #{@acid}, #{@code}, #{@name}")


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
    "c[#{@id}:#{@code} #{@credits} #{dbg.bals([@isSelected()])} #{@period}]"
