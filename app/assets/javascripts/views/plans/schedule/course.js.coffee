class @Course

  constructor: (data, periodsById) ->
    @isSelected          = ko.observable(false)
    @hilightPrereq       = ko.observable(false)
    @hilightPrereqTo     = ko.observable(false)
    @isInstanceBound     = ko.observable(false)
    @isMisordered        = ko.observable(false)
    @isMisscheduled      = ko.observable(false)

    @length              = ko.observable().extend({integer: {min: 1, max:  6}})  # Length in periods
    @credits             = ko.observable().extend({integer: {min: 0, max: 99}})
    @grade               = ko.observable().extend({integer: {min: 0, max:  5}})

    @tooltip             = ko.observable('')

    @locked              = false             # Is the course immovable?
    @position            = ko.observable({x: 0, y: 0, height: 1})

    @instancesByPeriodId = {}                # periodId => CourseInstance
    @instanceCount       = 0
    @avgInstanceLength   = 0
    @periods             = []                # Periods on which this course is arranged
    @prereqs             = {}                # Prerequisite courses. planCourseId => Course
    @prereqTo            = {}                # Courses for which this course is a prereq. planCourseId => Course object
    @prereqPaths         = []                # Raphael paths to prerequirement courses
    @allPrereqsInPlan    = false             #
    @period              = undefined         # Scheduled period
    @slot                = undefined         # Slot number that this course occupies
    @unschedulable       = false             # true if period allocation algorithm cannot find suitable period

    # The course instance we are bound to (by length as well):
    @courseInstance      = undefined

    @competences         = []                # Competences a prereq-to this is
    @affectedPeriods     = []                # Periods to which this course extends to atm.


    this.loadJson(data || {}, periodsById)

    # On length change we need to update the DOM (make the box longer or
    # shorter), but to avoid a slot mess, we go through regular period
    # change procedures as well.
    @length.subscribe ((oldValue) ->
      if @period and PlanView::ISREADY
        @periodTmp = @period
        @lengthTmp = oldValue
        @setPeriod(undefined)
    ), @, "beforeChange"

    # See prev. comment
    @length.subscribe (newValue) =>
      #dbg.lg("#{@}.length(#{newValue})")
      if @periodTmp and PlanView::ISREADY
        sqna = @periodTmp.sequenceNumber
        sqnb = @periodTmp.getNextPeriod(newValue - 1).sequenceNumber
        lenlack = newValue + sqna - sqnb - 1
        dbg.lg("len: #{@lengthTmp} -> #{newValue}  (#{sqna} - #{sqnb})")
        dbg.lg("lenlack: #{lenlack}!!")
        if lenlack > 0
          @periodTmp = @periodTmp.getPreviousPeriod(lenlack)
        @setPeriod(@periodTmp)
        #@slot = @period.addCourse(this)
        @updatePosition()

    # On credit change
    @credits.subscribe (newValue) =>
      #dbg.lg("#{@}.credits.subs type:#{type(newValue)} (#{@credits()})")
      for competence in @competences
        competence.updatePrereqCredits( @planCourseId, newValue )

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
      isCustomized = false # @credits() != @scopedCredits
      
      # FIXME: getter should not cause side effects
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
        competence.updatePrereqGrade(@planCourseId, newValue)
      # Check the period & grade related flag "isMisscheduled"
      # NB: Also calls updateTooltip, so no need to call it here
      @updateMisscheduledFlag()

  
   # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data, periodsById) ->
    localized_description = data['abstract_course']['localized_description'] || {}

    @planCourseId        = data['id']
    @abstractId          = data['abstract_course_id']
    @prereqIds           = data['abstract_prereq_ids'] || []
    @code                = data['abstract_course']['code'] || ''
    @name                = data['abstract_course']['localized_name'] || ''
    @min_credits         = data['abstract_course']['min_credits'] || 0
    @max_credits         = data['abstract_course']['max_credits'] || 0
    @periodInfo          = localized_description['period_info']
    @credits(data['credits'] || 0)
    @length(data['length'] || 1)
    @grade(data['grade'] || 0)
    
    if @min_credits
      if @max_credits && @min_credits != @max_credits
        @length_string = "#{@min_credits} - #{@max_credits}"
      else
        @length_string = "#{@min_credits}"
    else
      @length_string = '?'

    periodId = data['period_id']
    if periodId?
      @period = periodsById[periodId]
      #dbg.lg("Unknown periodId #{periodId}") unless @period

    for instance_data in data['abstract_course']['course_instances']
      period = periodsById[instance_data['period_id']]
      # It can be expected that many instances are irrelevant
      continue unless period?
      courseInstance = new CourseInstance(period, instance_data['length'])
      @periods.push(period)
      @instancesByPeriodId[period.id] = courseInstance
      @instanceCount++
      # Maintain an average of instance lengths which is used later to guess lengths of unknown instances
      @avgInstanceLength = (@avgInstanceLength * (@instanceCount - 1) + courseInstance.length) / @instanceCount

    @avgInstanceLength = undefined if @avgInstanceLength == 0


  # Serializes the model for sending it back to the database
  asHash: ->
    credits = @credits()
    length = @length()
    grade = @grade()

    hash = { 'plan_course_id': @planCourseId }
    #hash['scoped_course_id'] = @scopedId if @scopedId
    hash['credits'] = credits if credits > 0
    hash['period_id'] = @period.id if @period?
    hash['length'] = length if length > 0
    hash['grade'] = grade if grade >= 0

    return hash
  
  
  # Determines whether the model's core attributes have been changed.
  hasChanged: ->
    return true if @oCredits != @credits()

    if @period?
      return true if @oPeriodId != @period.id
    else
      return true if @oPeriodId != undefined

    return true if @oLength != @length()

    return true if @oGrade != @grade()

    return false


  # Resets the originals by which it is determined whether the model has been changed
  resetOriginals: ->
    @oCredits = @credits()
    if @period? then @oPeriodId = @period.id else @oPeriodId = undefined
    @oLength = @length()
    @oGrade = @grade()

  
  # Updates the tooltip
  updateTooltip: ->
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

    return period


  # Check the period & grade related flag "isMisscheduled"
  updateMisscheduledFlag: ->
    endPeriod = @getEndPeriod()
    @isMisscheduled(
      not endPeriod? or
      (endPeriod.isOld and not @grade() > 0) or
      ((not (@period.isOld or @period.isNow)) and @grade() > 0)
    )
    @updateTooltip()


  # Update the grade display
  updateGradeDisplay: ->
    return unless @period?
    if @period.isOld or @period.isNow
      $('.well #grade').show()
      #$('.well #grade').slideDown(500)
    else
      $('.well #grade').hide()
      #$('.well #grade').slideUp(500)


 
  # The selected status change handler
  setSelected: (isSelected) ->
    @isSelected(isSelected)

    # Update the grade display
    @updateGradeDisplay()

    # Hilight prereqs
    for planCourseId, other of @prereqs
      other.hilightPrereq(isSelected)

    # Hilight courses for which this is a prereq
    for planCourseId, other of @prereqTo
      other.hilightPrereqTo(isSelected)

    # Hilight the periods that have this course
    for period in @periods
      period.isReceiver(isSelected)

    O4.logger.log("cc #{@abstractId} #{@planCourseId}") if isSelected && O4.logger # click course

  # Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
  addPrereq: (other) ->
    @prereqs[other.planCourseId] = other
    other.prereqTo[@planCourseId] = this


  # Returns whether the course has prerequisite courses or not
  hasPrereqs: ->
    for planCourseId, course of @prereqs
      return true
    return false
    
  # Returns whether the course is prereq to other courses or not
  hasPostreqs: ->
    for planCourseId, course of @prereqs
      return true
    return false


  # Returns prerequisite courses as a list
  getPrereqs: ->
    prereqs = []
    for planCourseId, course of @prereqs
      prereqs.push(course)

    prereqs.sort (a, b) ->
      return a.code.localeCompare(b.code)

    return prereqs

  # Returns courses for which this course is a prereq as a list
  getPostreqs: ->
    postreqs = []
    for planCourseId, course of @prereqTo
      postreqs.push(course)

    postreqs.sort (a, b) ->
      return a.code.localeCompare(b.code)

    return postreqs


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
    if @period? and not (@period.isOld or @period.isNow)
      @grade(0)

    # Update the grade display
    @updateGradeDisplay()

    # Check the period & grade related flag "isMisscheduled"
    # NB: Also calls updateTooltip, so no need to call it here
    @updateMisscheduledFlag()

    # Add course to the new period
    @distributeCredits()
    @slot = @period?.addCourse(this)
    #dbg.lg("slot: #{@slot}.")


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

    for planCourseId, other of @prereqs
      isMisordered = true if other.period? && @period? && other.period.laterOrEqual(@period)
      other.updateReqWarnings(depth) if depth > 0

    for planCourseId, other of @prereqTo
      isMisordered = true if other.period? && @period? && other.period.earlierOrEqual(@period)
      other.updateReqWarnings(depth) if depth > 0

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
    for planCourseId, other of @prereqTo
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
  postponeAfterPrereqs: (earliestAllowedPeriod) ->
    # Only move if the course has not been locked into its current period
    return if @locked

    # Find the latest prereq
    latestPeriod = false
    for planCourseId, prereq of @prereqs
      period = prereq.getPeriod()
      latestPeriod = period if period? && (!latestPeriod || period.laterThan(latestPeriod))

    return unless latestPeriod

    # Put course on the next period after latest prereq
    targetPeriod = latestPeriod.getNextPeriod() || latestPeriod

    # Don't schedule courses before current period
    if earliestAllowedPeriod && targetPeriod.earlierThan(earliestAllowedPeriod)
      targetPeriod = earliestAllowedPeriod

    postponeTo(targetPeriod)


  sdbg: ->
    "c[#{@planCourseId}:#{@code}]"


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@planCourseId}:#{@code} #{dbg.bals([@isInstanceBound(),@isCustomized(),@isMisscheduled(),@isMisordered()])} #{@credits()} #{@length()} #{@grade()} (#{@courseInstance?.length} #{@oGrade})]"
    # n:#{@name}
