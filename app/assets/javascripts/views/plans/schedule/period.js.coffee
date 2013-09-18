class @Period

  ALL: []
  BYID: {}
  NOW: new Date().toISOString()
  CURRENT: undefined

  PERIODS_IN_YEAR: 6
  UNDERBOOKED_LIMIT: 11  # determines the period credit total limits for css warning classes
  OVERBOOKED_LIMIT: 19   #   see @creditsStatus


  createFromJson: (data) ->
    periodCounter = 0
    previousPeriod = undefined

    for raw_period in data
      period = new Period(raw_period)
      period.sequenceNumber = periodCounter
      period.previousPeriod = previousPeriod
      previousPeriod.nextPeriod = period if previousPeriod
      previousPeriod = period
      periodCounter++

      console.log "Warning: period id collision at #{@id}!" if @BYID[period.id]
      @BYID[period.id] = period
      @ALL.push(period)

    # Make sure we always have current period. (This is relevant if the
    # studyplan begins in the future.)
    Period::CURRENT ||= @ALL[0]


  constructor: (data) ->
    @isSelected    = ko.observable(false)
    @isReceiver    = ko.observable(false)
    @droppedCourse = ko.observable()

    # TODO: specify event handler in the binding
    @droppedCourse.subscribe (course) =>
      #dbg.lg("#{@}::droppedCourse(#{course})!")
      #console.log "Period: setPeriod"
      course.setPeriod(this)

      #console.log "Period: updatePosition"
      course.updatePosition()
      course.updateReqWarnings()


    @position         = ko.observable({y: 0}) # Course position
    @courses          = ko.observableArray()  # Courses that have been put to this period
    @slots            = []                    # Array index is slot (column) number. Value is Course occupying the slot or false
    @previousPeriod   = undefined             # Reference to previous sibling
    @nextPeriod       = undefined             # Reference to next sibling
    @sequenceNumber   = undefined             # Sequence number to allow easy testing of the order of periods

    @loadJson(data || {})

    @affectingCourses = []                    # Courses that extend to this period
    @credits          = ko.observable(0)
    @creditsStatus    = undefined
    @creditsTooltip   = undefined

    @credits.subscribe (newValue) =>
      #console.log("Foo! #{@id}")
      credits = newValue
      @creditsStatus = ''
      @creditsTooltip = O4.schedule.i18n.period_credits_tooltip_neutral
      if credits < @UNDERBOOKED_LIMIT
        @creditsStatus = 'underbooked'
        @creditsTooltip = O4.schedule.i18n.period_credits_tooltip_underbooked if credits > 0
      else if credits > @OVERBOOKED_LIMIT
        @creditsStatus = 'overbooked'
        @creditsTooltip = O4.schedule.i18n.period_credits_tooltip_overbooked


  loadJson: (data) ->
    # Load basic data
    @id = data['id']
    @name = data['localized_name'] || ''
    @beginsAt = data['begins_at']
    @endsAt = data['ends_at']
    
    @isSummer      = 'S' == @name.substr(@name.length - 1)

    # Set time dependent flags
    @isNow = false
    if @endsAt < Period::NOW
      @isOld = true
    else
      @isOld = false
      if @beginsAt < Period::NOW
        @isNow = true
        Period::CURRENT = this

  earlierThan: (other) ->
    return this.sequenceNumber < other.sequenceNumber


  earlierOrEqual: (other) ->
    return this.sequenceNumber <= other.sequenceNumber


  laterThan: (other) ->
    return this.sequenceNumber > other.sequenceNumber


  laterOrEqual: (other) ->
    return this.sequenceNumber >= other.sequenceNumber


  # Returns the nth period prior or the farthest if none
  getPreviousPeriod: (nth = 1) ->
    return this if nth <= 0 or not @previousPeriod
    period = @previousPeriod
    while nth -= 1 > 0
      if period?.previousPeriod
        period = period.previousPeriod
    return period


  # Returns the nth period forward or the farthest if none
  getNextPeriod: (nth = 1) ->
    return this if nth <= 0 or not @nextPeriod
    period = @nextPeriod
    while nth -= 1 > 0
      if period?.nextPeriod
        period = period.nextPeriod
    return period


  # Gets the neighbour
  actOnCommand: (planView, keyCode) ->
    if keyCode == 38  # up
      period = @previousPeriod
    else if keyCode == 40  # down
      period = @nextPeriod
    else if keyCode == 33  # page up
      period = @getPreviousPeriod(@PERIODS_IN_YEAR)
    else if keyCode == 34  # page down
      period = @getNextPeriod(@PERIODS_IN_YEAR)
    if period?
      planView.selectObject(period)
      return true
    return false


  # The selected status change handler
  setSelected: (isSelected) ->
    @isSelected(isSelected)


  # Puts a course on this period.
  addCourse: (course, slot) ->
    #dbg.lg("#{@}::add #{course} L:#{course.length()}.")
    # Add the course
    @courses.push(course)

    length = course.length()  # Length in periods

    # Check that the slot is free. Find a free slot if it's occupied.
    if !slot || !this.isSlotFree(slot, length)
      slot = this.findFreeSlot(length)

    # Occupy slots
    this.occupySlot(slot, length, course)

    return slot

  isSummer: ->
    false

  # Removes a course from this period.
  removeCourse: (course) ->
    #dbg.lg("#{@}::rm #{course} L:#{course.length()}.")
    # Remove the course
    @courses.splice(@courses.indexOf(course), 1)

    # Free slots
    this.freeSlot(course.slot, course.length())


  findFreeSlot: (length) ->
    for slot in [0...100]
      return slot if this.isSlotFree(slot, length)


  # Returns true if the given slot is free on this and the given number of succeeding periods.
  isSlotFree: (slot, length) ->
    return false if this.slots[slot]

    if !@nextPeriod || length <= 1
      return true
    else
      return @nextPeriod.isSlotFree(slot, length - 1)


  # Occupies slots in this and succeeding periods.
  # @param slot The slot to be freed.
  # @param length How many periods to span
  # @param course Course that occupies the slot.
  occupySlot: (slot, length, course) ->
    @slots[slot] = course
    @nextPeriod.occupySlot(slot, length - 1, course) if length > 1 && @nextPeriod


  # Frees slots in this and succeeding periods.
  # @param slot The slot to be freed.
  # @param length How many periods to span
  freeSlot: (slot, length) ->
    course = @slots[slot]
    @slots[slot] = false
    @nextPeriod.freeSlot(slot, length - 1) if length > 1 && @nextPeriod


  addAffectingCourse: (course) ->
    @affectingCourses.push(course)


  removeAffectingCourse: (course) ->
    @affectingCourses.splice(@affectingCourses.indexOf(course), 1)


  # Renders the object into a string for debugging purposes
  toString: ->
    "p[#{@id}]:{ n:#{@name} }"
