class @Course

  ALL: []
  BYSCOPEDID: {}
  BYABSTRACTID: {}

  constructor: (data) ->
    @isSelected          = ko.observable(false)
    @hilightPrereq       = ko.observable(false)
    @hilightPrereqTo     = ko.observable(false)
    @isInstanceBound     = ko.observable(false)
    @isMisordered        = ko.observable(false)
    @isMisscheduled      = ko.observable(false)

    @length              = ko.observable().extend({integer: {min: 1, max:  4}})  # Length in periods
    @credits             = ko.observable().extend({integer: {min: 0, max: 99}})
    @grade               = ko.observable().extend({integer: {min: 0, max:  5}})

    @tooltip             = ko.observable('')

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
    @unschedulable       = false             # true if period allocation algorithm cannot find suitable period

    # The course instance we are bound to (by length as well):
    @courseInstance      = undefined

    @competences         = []                # Competences a prereq-to this is
    @affectedPeriods     = []                # Periods to which this course extends to atm.


    this.loadJson(data || {})

    # On length change we need to update the DOM (make the box longer or
    # shorter), but to avoid a slot mess, we go through regular period
    # change procedures as well.
    @length.subscribe ((oldValue) ->
      if @period and PlanView::ISREADY
        @periodTmp = @period
        @setPeriod(undefined)
    ), @, "beforeChange"

    # See prev. comment
    @length.subscribe (newValue) =>
      #dbg.lg("#{@}.length(#{newValue})")
      if @periodTmp and PlanView::ISREADY
        @setPeriod(@periodTmp)
        #@slot = @period.addCourse(this)
        @updatePosition()

    # On credit change
    @credits.subscribe (newValue) =>
      #dbg.lg("#{@}.credits.subs type:#{type(newValue)} (#{@credits()})")
      for competence in @competences
        competence.updatePrereqCredits( @scopedId, newValue )

    @creditsPerP = ko.computed =>
      #dbg.lg("#{@} credits update -> #{@credits()}/#{@length()}")
      return @credits() / @length()

    @creditsPerP.subscribe ((oldValue) ->
      #dbg.lg("#{@}.creditsPerP.subs before")
      @deDistributeCredits(oldValue)
    ), @, "beforeChange"

    @creditsPerP.subscribe (newValue) =>
      #dbg.lg("#{@}.creditsPerP.subs")
      @distributeCredits()

    @isCustomized = ko.computed =>
      isCustomized = @credits() != @scopedCredits
      @courseInstance = @instancesByPeriodId[@period?.id]
      isInstanceBound = @courseInstance?
      if isInstanceBound and (@length() != @courseInstance.length)
        isInstanceBound = false
        # Lose the courseInstance if the course differs from it
        @courseInstance = undefined

      #dbg.lg("#{@sdbg()}.isCustomized() #{dbg.bals([isCustomized,isInstanceBound])} (#{@credits()}-#{@scopedCredits}, #{@length()}-#{@courseInstance?.length})")

      # Update the isInstanceBound flag
      # NB: Done here to capture length changes.
      @isInstanceBound(isInstanceBound)

      return isCustomized

    @isCustomized.subscribe (newValue) =>
      # Update tooltip when changes to course specs (credits & lenght) are made
      @updateTooltip()


    @grade.subscribe (newValue) =>
      for competence in @competences
        competence.updatePrereqGrade( @scopedId, newValue )
      # Check the period & grade related flag "isMisscheduled"
      # NB: Also calls updateTooltip, so no need to call it here
      @updateMisscheduledFlag()

  createFromJson: (data) ->
    # Load courses
    for dat in data
      course = new Course(dat)

    # Load course prerequirements
    for course in @ALL
      for prereqId in course.prereqIds
        prereq = @BYSCOPEDID[prereqId]
        unless prereq
          dbg.lg("Unknown prereqId #{prereqId}!")
          continue
        course.addPrereq(prereq)


  # Updates the tooltip
  updateTooltip: ->
    #dbg.lg("#{@}::updateTooltip()...")
    alarms = ['']
    notices = ['']
    alarms.push(O4.schedule.i18n.course_tooltip_misordered) if @isMisordered()
    alarms.push(O4.schedule.i18n.course_tooltip_misscheduled) if @isMisscheduled()
    notices.push(O4.schedule.i18n.course_tooltip_uninstanced) if not @isInstanceBound()
    notices.push(O4.schedule.i18n.course_tooltip_customized) if @isCustomized()
    notices.push(O4.schedule.i18n.course_tooltip_passed) if @grade() > 0

    tooltip = ''
    tooltip += O4.schedule.i18n.course_tooltip_intro_alarm + alarms.join('\n - ') + '\n' if alarms.length > 1
    tooltip += O4.schedule.i18n.course_tooltip_intro_notice + notices.join('\n - ') + '\n' if notices.length > 1
    @tooltip(tooltip)


  # Returns the period in which this course ends
  getEndPeriod: ->
    remaining_distance = @length()
    period = @period
    while period and remaining_distance -= 1
      period = period.nextPeriod
    #dbg.lg("#{@}::getEndPeriod(#{@period}) -> #{period}")
    return period


  # Check the period & grade related flag "isMisscheduled"
  updateMisscheduledFlag: ->
    endPeriod = @getEndPeriod()
    @isMisscheduled(not endPeriod? or ((endPeriod.isOld and not @grade() > 0) or ((not endPeriod.isOld) and @grade() > 0)))
    @updateTooltip()


  # Update the grade display
  updateGradeDisplay: ->
    return unless @period?
    if @period.isOld
      $('.well #grade').show()
      #$('.well #grade').slideDown(500)
    else
      $('.well #grade').hide()
      #$('.well #grade').slideUp(500)


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    #dbg.lg("#{@}::data: #{JSON.stringify(data)}!")

    @abstractId          = data['abstract_course']['id']
    @code                = data['abstract_course']['code'] || ''
    @name                = data['abstract_course']['localized_name'] || ''
    @scopedId            = data['scoped_course']['id']
    @scopedCredits       = data['scoped_course']['credits']
    @prereqIds           = data['scoped_course']['prereq_ids'] || []
    @credits(data['credits'] || @scopedCredits || 0)
    @length(data['length'] || 0)
    @grade(data['grade'] || 0)

    periodId = data['period_id']
    if periodId?
      @period = Period::BYID[periodId]
      dbg.lg("Unknown periodId #{periodId}") unless @period

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
      #dbg.lg( "course[#{@scopedId}]::addCInstance: #:#{@instanceCount} #{courseInstance}" )

    @avgInstanceLength = undefined if @avgInstanceLength == 0

    #dbg.lg("L:#{@length()}!")
    #dbg.lg("#{@}::L:#{@length()}!")

    # Map the object
    throw "ERROR: scopedId collision at #{@scopedId}!" if @BYSCOPEDID[@scopedId]?
    @BYSCOPEDID[@scopedId] = this
    throw "ERROR: abstractId collision at #{@abstractId}!" if @BYABSTRACTID[@abstractId]?
    @BYABSTRACTID[@abstractId] = this
    @ALL.push(this)


  # Determines whether the model's core attributes have been changed.
  hasChanged: ->
    #dbg.lg( "=> Was #{@name} changed?" )
    #dbg.lg( " - credits: #{@oCredits}  vs  #{@credits()}" )
    return true if @oCredits != @credits()
    #dbg.lg( " - period: #{@oPeriodId}  vs  #{@period.id}" )
    if @period?
      return true if @oPeriodId != @period.id
    else
      return true if @oPeriodId != undefined
    #dbg.lg( " - length: #{@oLength}  vs  #{@length()}" )
    return true if @oLength != @length()
    #dbg.lg( " - grade: #{@oGrade}  vs  #{@grade()}" )
    return true if @oGrade != @grade()
    #dbg.lg( "   NOT CHANGED!" )
    return false


  # Resets the originals by which it is determined whether the model has been changed
  resetOriginals: ->
    @oCredits = @credits()
    if @period? then @oPeriodId = @period.id else @oPeriodId = undefined
    @oLength = @length()
    @oGrade = @grade()


  # Serializes the model for sending it back to the database
  asHash: ->
    credits = @credits()
    length = @length()
    grade = @grade()

    hash = { scoped_course_id: @scopedId }
    hash['credits'] = credits if credits > 0
    hash['period_id'] = @period.id if @period?
    hash['length'] = length if length > 0
    hash['grade'] = grade if grade >= 0

    return hash


  # The selected status change handler
  setSelected: (isSelected) ->
    @isSelected(isSelected)

    # Update the grade display
    @updateGradeDisplay()

    # Hilight prereqs
    for scopedId, other of @prereqs
      other.hilightPrereq(isSelected)

    # Hilight courses for which this is a prereq
    for scopedId, other of @prereqTo
      other.hilightPrereqTo(isSelected)

    # Hilight the periods that have this course
    for period in @periods
      period.isReceiver(isSelected)


  # Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
  addPrereq: (other) ->
    @prereqs[other.scopedId]  = other
    other.prereqTo[@scopedId] = this


  # Returns whether the course has prerequisite courses or not
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
    for period in @affectedPeriods
      period.credits(period.credits() + @creditsPerP())


  # Cancels the effect of the previous function
  deDistributeCredits: (oldCPP) ->
    if not oldCPP? then oldCPP = @creditsPerP()
    return if not (oldCPP > 0)
    for period in @affectedPeriods
      period.credits(period.credits() - oldCPP)


  # Moves the course to the given period, to a free slot but does not update the DOM.
  # Updates @period and @slot and distributes credits to the affected periods.
  setPeriod: (period, doOverwriteLength = false) ->
    #dbg.lg("#{@}::setPeriod(#{period}) L:#{@length()}!")

    # Debind the course from its course instance if any
    @courseInstance = undefined

    # Remove course from previous period. Note: length must not be updated
    # before freeing the old slots.
    if @period
      @deDistributeCredits()
      @period.removeCourse(this)

      # Clear the affected relationships
      for prd in @affectedPeriods
        prd.removeAffectingCourse(this)
      @affectedPeriods = []

      # In order to not allow double dedistribution of credits at length change.
      @period = undefined

    # Get the available course instance
    courseInstance = @instancesByPeriodId[period.id] if period

    # The length is updated only if the  previous length is specified
    if doOverwriteLength
      # If an instance is available, its length is used
      if courseInstance?
        @length(courseInstance.length)
      # Otherwise, an average of instance lengths is used
      else if @avgInstanceLength
        @length(Math.round(@avgInstanceLength))
      # In case there are no instances at all, the length is set to a default
      else
        @length(1)

    # The course is set as bound to the available instance only if the lengths
    # match
    @courseInstance = courseInstance if @length() == courseInstance?.length

    # Even if the length is unchanged, the isInstanceBound flag must still be
    # updated
    @isInstanceBound(@courseInstance?)

    # Update the period
    @period = period

    # Update the affected periods array
    if @period
      prd = @period
      len = @length() + 1
      while prd and len -= 1
        @affectedPeriods.push(prd)
        prd.addAffectingCourse(this)
        prd = prd.nextPeriod

    # Autoreset grades for courses scheduled into the future
    if @period? and not @period.isOld
      @grade(0)

    # Update the grade display
    @updateGradeDisplay()

    # Check the period & grade related flag "isMisscheduled"
    # NB: Also calls updateTooltip, so no need to call it here
    @updateMisscheduledFlag()

    # Add course to the new period
    @distributeCredits()
    @slot = @period?.addCourse(this)
    dbg.lg("slot: #{@slot}.")


  # Updates the DOM elements to match model
  updatePosition: ->
        # Move the div
    pos = @position()
    pos.x = @slot * (PlanView.COURSE_WIDTH + PlanView.COURSE_MARGIN_X) + PlanView.COURSE_MARGIN_X
    pos.y = @period.position().y + PlanView.COURSE_MARGIN_Y
    pos.height = @length() * PlanView.PERIOD_HEIGHT - 2 * (PlanView.COURSE_MARGIN_Y + PlanView.COURSE_PADDING_Y)

    pos.updated = false     # This hack is needed to distinguish from unnecesary updates triggered by other bindings
    @position.valueHasMutated()


  # Update warnings FIXME: updates the original source twice...
  updateReqWarnings: (depth) ->
    if depth > 0 then depth = depth - 1 else depth = 1
    #dbg.lg( "Course[#{@scopedId}]:uRW(#{depth}) #{@period.sequenceNumber}" )

    for scopedId, other of @prereqs
      isMisordered = true if other.period? && @period? && other.period.laterOrEqual(@period)
      other.updateReqWarnings(depth) if depth > 0

    for scopedId, other of @prereqTo
      isMisordered = true if other.period? && @period? && other.period.earlierOrEqual(@period)
      other.updateReqWarnings(depth) if depth > 0

    #dbg.lg( "Course[#{@scopedId}].isMisordered: #{isMisordered}." )
    @isMisordered(isMisordered)
    @updateTooltip()


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
        dbg.lg("#{other.name} depends on #{@name}. Postponing to #{targetPeriod}.")
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


  sdbg: ->
    "c[#{@scopedId}:#{@code}]"


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@scopedId}:#{@code} #{dbg.bals([@isInstanceBound(),@isCustomized(),@isMisscheduled(),@isMisordered()])} #{@credits()} #{@length()} #{@grade()} (#{@scopedCredits} #{@courseInstance?.length} #{@oGrade})]"
    # n:#{@name}
