class @Period

  constructor: (data) ->
    @credits = ko.observable(0)
    @droppedCourse = ko.observable()
    @hilight = ko.observable(false)
    @oldPeriod = ko.observable(false)
  
    # TODO: specify event handler in the binding
    @droppedCourse.subscribe (course) =>
      course.setPeriod(this)
      course.updatePosition()
      course.updateWarnings()
      
    @position = ko.observable({y: 0})
    @coursesById = {}              # Courses that have been put to this period
    #@courseInstances = {}          # Courses that are available on this period. courseId => courseInstance
    @slots            = []         # Array index is slot (column) number. Value is Course occupying the slot or false
    @previousPeriod   = undefined  # Reference to previous sibling
    @nextPeriod       = undefined  # Reference to next sibling
    @sequenceNumber   = undefined  # Sequence number to allow easy testing of the order of periods
#     
#     
#     element.droppable
#       drop: courseDropped,
#       accept: isCourseAccepted 
# 
    this.loadJson(data || {})

  loadJson: (data) ->
    @id = data['id']
    @name = data['localized_name'] || ''
    @period_number = data['number']


  earlierThan: (other) ->
    return this.sequenceNumber < other.sequenceNumber

  earlierOrEqual: (other) ->
    return this.sequenceNumber <= other.sequenceNumber

  laterThan: (other) ->
    return this.sequenceNumber > other.sequenceNumber

  laterOrEqual: (other) ->
    return this.sequenceNumber >= other.sequenceNumber

#   getPreviousPeriodUntilCurrent: ->
#     if this.previousPeriod.laterOrEqual(this.currentPeriod)
#       return this.previousPeriod
#     else
#       return null


  getPreviousPeriod: ->
    return this.previousPeriod

  getNextPeriod: ->
    return this.nextPeriod


  # Puts a course on this period.
  addCourse: (course, slot) ->
    @coursesById[course.id] = course
    
    length = course.length  # Length in periods
    
    # Check that the slot is free. Find a free slot if it's occupied.
    if !slot || !this.isSlotFree(slot, length)
      slot = this.findFreeSlot(length)
  
    # Occupy slots
    this.occupySlot(slot, length, course)
    
    return slot


  updateCredits: ->
    credits = 0
    #for id, course of @coursesById
    #  credits += course.credits
    
    
    @credits(credits)


  removeCourse: (course) ->
    # Remove course from the list
    delete @coursesById[course.id]
    
    # Free slots
    this.freeSlot(course.slot, course.length)


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
    
    @credits(@credits() + course.credits())
    
    @nextPeriod.occupySlot(slot, length - 1, course) if length > 1 && @nextPeriod


  # Frees slots in this and succeeding periods.
  # @param slot The slot to be freed.
  # @param length How many periods to span
  freeSlot: (slot, length) ->
    course = @slots[slot]
    @slots[slot] = false
    
    # FIXME: this breaks if user changes credits before removing course
    @credits(@credits() - course.credits()) if course
    
    @nextPeriod.freeSlot(slot, length - 1) if length > 1 && @nextPeriod


#   #  Decides whether droppable should accept given draggable.
#   isCourseAccepted(draggable) ->
#     course = draggable.data('object')
#     period = $(this).data('object')
#     
#     return true
#     # FIXME
#     
#     return period.laterOrEqual(planView.currentPeriod) && period.courseAvailable(course)
# 
# 
#   # Handles course drop events.
#   courseDropped: (event, ui) ->
#     period = $(this).data('object')
#     course = ui.draggable.data('object')
# 
#     # Draggable needs to know that drop succeeded
#     ui.draggable.data('dropped', true)
#     
#     # Find the course instance
#     course.setPeriod(period)
#     if period.courseInstances[course.getCode()]
#       course.element.removeClass('noinstance')
#     else
#       # If there is no instance on that period, show warning
#       course.element.addClass('noinstance')
#     
#     
#     if (planView.settings.satisfyReqsAutomatically)
#       # Move prereqs before the course
#       course.satisfyPrereqs()
#       
#       # Move postreqs after the course
#       course.satisfyPostreqs()
