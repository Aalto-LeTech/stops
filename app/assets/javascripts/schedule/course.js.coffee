class @Course

  ALL: []
  BYSCOPEDID: {}
  BYABSTRACTID: {}


  createFromJson: (data, passedData) ->
    # Load courses
    for dat in data
      course = new Course(dat)

    # Load course prerequirements
    for course in @ALL
      for prereqId in course.prereqIds
        prereq = @BYSCOPEDID[prereqId]
        unless prereq
          console.log("Unknown prereqId #{prereqId}!")
          continue
        course.addPrereq(prereq)

    # Load passed courses
    for dat in passedData
      course = @BYABSTRACTID[dat['abstract_course_id']]
      unless course
        console.log("Unknown course #{dat['abstract_course_id']}!")
        continue
      # Save the period
      periodId = dat['period_id']
      if not periodId?
        console.log("Course \"#{course.name}\" was probably passed on a custom instance since no periodId was given.")
      else
        course.period = Period::BYID[periodId]
        unless course.period
          console.log("Unknown periodId #{periodId}")
      # Save other data
      course.credits(dat['credits'])
      course.grade(dat['grade'])


  constructor: (data) ->
    @hilightSelected     = ko.observable(false)
    @hilightPrereq       = ko.observable(false)
    @hilightPrereqTo     = ko.observable(false)
    @misordered          = ko.observable(false)

    @locked              = false             # Is the course immovable?
    @position            = ko.observable({x: 0, y: 0, height: 1})

    @instancesByPeriodId = {}                # periodId => CourseInstance
    @instanceCount       = 0
    @avgInstanceLength   = 0
    @periods             = []                # Periods on which this course is arranged
    @prereqs             = {}                # Prerequisite courses. scopedId => Course
    @prereqTo            = {}                # Courses for which this course is a prereq. scopedId => Course object
    @prereqPaths         = []                # Raphael paths to prerequirement courses
    @period              = undefined         # Scheduled period
    @slot                = undefined         # Slot number that this course occupies
    @length              = ko.observable()   # Length in periods
    @unschedulable       = false             # true if period allocation algorithm cannot find suitable period

    @credits             = ko.observable()
    @grade               = ko.observable()
    @courseInstance      = undefined

    this.loadJson(data || {})

    @creditsPerP = ko.computed =>
      @credits(parseInt(@credits()))
      @length(parseInt(@length()))
      #console.log("c[#{@scopedId}] credits update -> #{@credits()}/#{@length()}")
      return @credits() / @length()

    @creditsPerP.subscribe ((oldValue) ->
      @deDistributeCredits(oldValue)
    ), @, "beforeChange"

    @creditsPerP.subscribe (newValue) =>
      @distributeCredits()

    @customized = ko.computed =>
      #if @courseInstance then s = "#{@courseInstance.length}" else s = "?"
      #console.log("customized: #{@code} : (#{@credits()} vs #{@scopedCredits}, #{@length()} vs #{s})")
      return true if @credits() != @scopedCredits
      if @courseInstance
        return true if @length() != @courseInstance.length
      return false
#     if @courseInstance then s = "#{@courseInstance.length}" else s = "?"
#     console.log("cust #{customized} <- #{@name} : (#{@credits()} vs #{@scopedCredits}, #{@length()} vs #{s})")


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->
    @abstractId          = data['abstract_course']['id']
    @code                = data['abstract_course']['code'] || ''
    @name                = data['abstract_course']['localized_name'] || ''
    @scopedId            = data['scoped_course']['id']
    @scopedCredits       = data['scoped_course']['credits']
    @prereqIds           = data['scoped_course']['prereq_ids'] || []
    @credits(data['credits'] || @scopedCredits || 0)
    @length(data['length'] || 1)

    periodId = data['period_id']
    if periodId != undefined
      @period = Period::BYID[periodId]
      console.log("Unknown period ID #{periodId}") unless @period

    for dat in data['abstract_course']['course_instances']
      period = Period::BYID[dat['period_id']]
      # It can be expected that many instances are irrelevant
      continue unless period?
      courseInstance = new CourseInstance(period, dat['length'])
      @periods.push(period)
      @instancesByPeriodId[period.id] = courseInstance
      @instanceCount++
      # Maintain an average of instance lengths which is used later to guess
      # lengths of unknown instances
      @avgInstanceLength = (@avgInstanceLength * (@instanceCount - 1) + courseInstance.length) / @instanceCount
      #console.log( "course[#{@scopedId}]::addCInstance: #:#{@instanceCount} #{courseInstance}" )

    # Map the object
    throw "ERROR: scopedId collision at #{@scopedId}!" if @BYSCOPEDID[@scopedId]?
    @BYSCOPEDID[@scopedId] = this
    throw "ERROR: abstractId collision at #{@abstractId}!" if @BYABSTRACTID[@abstractId]?
    @BYABSTRACTID[@abstractId] = this
    @ALL.push(this)


  # Determines whether the model's core attributes have been changed.
  hasChanged: ->
    #console.log( "=> Was #{@name} changed?" )
    #console.log( " - credits: #{@oCredits}  vs  #{@credits()}" )
    return true if @oCredits != @credits()
    #console.log( " - period: #{@oPeriodId}  vs  #{@period.id}" )
    if @period?
      return true if @oPeriodId != @period.id
    else
      return true if @oPeriodId != undefined
    #console.log( " - length: #{@oLength}  vs  #{@length()}" )
    return true if @oLength != @length()
    #console.log( " - grade: #{@oGrade}  vs  #{@grade()}" )
    return true if @oGrade != @grade()
    #console.log( "   NOT CHANGED!" )
    return false


  # Resets the originals by which it is determined whether the model has been changed
  resetOriginals: ->
    @oCredits = @credits()
    if @period? then @oPeriodId = @period.id else @oPeriodId = undefined
    @oLength = @length()  # FIXME: make me changeable
    @oGrade = @grade()


  # Serializes the model for sending it back to the database
  toJson: ->
    credits = parseInt(@credits())
    length = parseInt(@length())
    grade = parseInt(@grade())

    json = { scoped_course_id: @scopedId }
    json['credits'] = credits if credits > 0
    json['period_id'] = @period.id if @period?
    json['length'] = length if length > 0  # FIXME: should study_plan_course model have one?
    json['grade'] = grade if grade > 0

    return json


  # Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
  addPrereq: (other) ->
    @prereqs[other.scopedId]  = other
    other.prereqTo[@scopedId] = this


  # Returns prerequisite courses as a list
  hasPrereqs: ->
    for scopedId, course of @prereqs
      return true
    return false


  # Returns prerequisite courses as a list
  getPrereqs: ->
    prereqs = []
    for scopedId, course of @prereqs
      prereqs.push( course )

    prereqs.sort (a, b) ->
      return a.code.localeCompare(b.code)

    return prereqs


  # Distributes the course's credit weight on the periods it extends to
  distributeCredits: ->
    #console.log("c[#{@scopedId}] dcr c/l:#{}) p:#{@period}")
    return if not @period or not @length()
    period = @period
    remaining_extent = @length() + 1
    while remaining_extent -= 1
      #console.log("c[#{@scopedId}] dcr (#{@credits()}/#{@length()}) to #{period}")
      period.credits(period.credits() + @creditsPerP())
      period = period.nextPeriod


  # Cancels the effect of the previous function
  deDistributeCredits: (oldCPP) ->
    #console.log("c[#{@scopedId}] ddcr c/l:#{@credits()}/#{@length()} p:#{@period}")
    return if not @period or not @length()
    if not oldCPP? then oldCPP = @creditsPerP()
    return if not (oldCPP > 0)
    period = @period
    remaining_extent = @length() + 1
    while remaining_extent -= 1
      #console.log("c[#{@scopedId}] ddcr #{oldCPP} (x #{@length()}) from #{period}")
      period.credits(period.credits() - oldCPP)
      period = @period.nextPeriod


  # Moves the course to the given period, to a free slot but does not update the DOM.
  # Updates @period and @slot and distributes credits to the affected periods.
  setPeriod: (period) ->
    #console.log("#{@code} period => #{period} ...")
    # Remove course from previous period. Note: length must not be updated before freeing the old slots.
    if @period
      @deDistributeCredits()
      @period.removeCourse(this)
      # In order to not allow double dedistribution of credits at length change.
      @period = undefined

    # Update the length
    @courseInstance = @instancesByPeriodId[period.id]

    # The length is updated and with a guess if no actual instance is available
    if @courseInstance then @length(@courseInstance.length) else @length(Math.round(@avgInstanceLength))

    # Update the period
    @period = period

    # Add course to the new period
    @distributeCredits()
    @slot = period.addCourse(this)


  # Updates the DOM elements to match model
  updatePosition: ->
    #console.log("#{@code} positioning...")
    # Move the div
    pos = @position()
    pos.x = @slot * (PlanView.COURSE_WIDTH + PlanView.COURSE_MARGIN_X) + PlanView.COURSE_MARGIN_X
    pos.y = @period.position().y + PlanView.COURSE_MARGIN_Y
    pos.height = @length() * PlanView.PERIOD_HEIGHT - 2 * (PlanView.COURSE_MARGIN_Y + PlanView.COURSE_PADDING_Y)
    @position.valueHasMutated()


  # Update warnings FIXME: updates the original source twice...
  updateReqWarnings: (depth) ->
    if depth > 0 then depth = depth - 1 else depth = 1
    #console.log( "Course[#{@scopedId}]:uRW(#{depth}) #{@period.sequenceNumber}" )

    for scopedId, other of @prereqs
      misordered = true if other.period? && @period? && other.period.laterOrEqual(@period)
      other.updateReqWarnings(depth) if depth > 0

    for scopedId, other of @prereqTo
      misordered = true if other.period? && @period? && other.period.earlierOrEqual(@period)
      other.updateReqWarnings(depth) if depth > 0

    #console.log( "Course[#{@scopedId}].misordered: #{misordered}." )
    @misordered(misordered)


  # Mark the course as unschedulable by the automatic scheduling algorithm
  # (i.e., there were no available periods with course instances late enough to satisfy prerequirements)
  markUnschedulable: () ->
    @unschedulable = true


  # Recursively moves forward all courses that require this course
  satisfyPostreqs: () ->
    # Quit recursion if this course is part of an unsolvable chain
    unless @period?
      markUnshedulable()
      return

    targetPeriod = @period.nextPeriod
    unless targetPeriod?
      # TODO: mark postreqs unschedulable
      return

    # Postpone postreqs that are earlier than this
    for scopedId, other of @prereqTo
      if !other.period? || @period.laterOrEqual(other.period)
        console.log("#{other.name} depends on #{@name}. Postponing to #{targetPeriod}.")
        other.postponeTo(targetPeriod) unless other.locked
        other.satisfyPostreqs()


  # Moves this course to the first available period starting from the given period.
  postponeTo: (requestedPeriod) ->
    #this.setPeriod(period);

    # If no instances are known for this course, put it on the requested period
    if (@instanceCount < 1)
      setPeriod(requestedPeriod)
      markUnschedulable()
      return

    #if (!this.unschedulable) {
    period = requestedPeriod
    while (period)
      if @instancesByPeriodId[period.id]
        setPeriod(period)
        return

      period = period.getNextPeriod()

    # No period could be found. Put it on the requested period
    setPeriod(requestedPeriod)
    markUnschedulable()


  # Moves the course forward after its prereqs (those that have been put on a period).
  # If no prereqs are found, course remains unmodified.
  postponeAfterPrereqs: () ->
    # Only move if the course has not been locked into its current period
    return if @locked

    # Find the latest prereq
    latestPeriod = false
    for scopedId, prereq of @prereqs
      period = prereq.getPeriod()
      latestPeriod = period if period? && (!latestPeriod || period.laterThan(latestPeriod))

    return unless latestPeriod

    # Put course on the next period after latest prereq
    targetPeriod = latestPeriod.getNextPeriod() || latestPeriod

    # Don't schedule courses before current period
    if targetPeriod.earlierThan(Period::currentPeriod)
      targetPeriod = Period::currentPeriod

    postponeTo(targetPeriod)


  # Renders the object into a string for debugging purposes
  toString: ->
    "crs[#{@scopedId}]:{ c:#{@code} n:#{@name} }"
