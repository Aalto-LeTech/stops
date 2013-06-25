class @Period

  constructor: (data) ->
    @credits = ko.observable(0)
    @courses = []
    this.loadJson(data || {})
  
#     element.data('object', this)     # Add a reference from element to this
#     this.element          = element  # Add a reference from this to element
#     
#     this.credits_element  = this.element.find('.period-credits')
#     
#     this.courses = {}               # Courses that have been put to this period
#     this.courseInstances = {}       # Courses that are available on this period. courseCode => courseInstance
#                                     # FIXME: Courses can now be added regardless of available instances
#     this.slots = []                 # Slots for parallel courses
#     this.slots            = []       # Slots for parallel courses
#     
#     this.previousPeriod   = false    # Reference to previous sibling
#     this.nextPeriod       = false    # Reference to next sibling
#     this.sequenceNumber              # Sequence number to allow easy comparison of periods
#     this.isCurrentPeriod  = element.data("current-period") === true
#     this.currentPeriod = this if (this.isCurrentPeriod) 
#     
#     this.id = element.data('id')     # Database id of this period
#     
#     element.droppable
#       drop: courseDropped,
#       accept: isCourseAccepted 
# 

  loadJson: (data) ->
    @id = data['id']
    @name = data['localized_name'] || ''
    @period_number = data['number']

# 
#   getId: ->
#     return this.id
# 
#   setSequenceNumber: (number) ->
#     this.sequenceNumber = number
# 
#   earlierThan: (other) ->
#     return this.sequenceNumber < other.sequenceNumber
# 
#   earlierOrEqual: (other) ->
#     return this.sequenceNumber <= other.sequenceNumber
# 
#   laterThan: (other) ->
#     return this.sequenceNumber > other.sequenceNumber
# 
#   laterOrEqual: (other) ->
#     return this.sequenceNumber >= other.sequenceNumber
# 
# 
#   # Sets the link from this period to the previous. This period is automatically added as the successor to the previous period.
#   setPreviousPeriod: (previousPeriod) ->
#     this.previousPeriod = previousPeriod
#     
#     if (previousPeriod)
#       previousPeriod.nextPeriod = this
# 
#       if (this.isCurrentPeriod)
#         # Propagate current period to previous periods
#         period = previousPeriod
#         while (period)
#           period.currentPeriod = this
#           period = period.getPreviousPeriod()
# 
#       else if (previousPeriod.currentPeriod)
#         # Propagate current period to next periods
#         this.currentPeriod = previousPeriod.currentPeriod
#   
#   
#   getPreviousPeriod: ->
#     return this.previousPeriod
# 
# 
#   getPreviousPeriodUntilCurrent: ->
#     if this.previousPeriod.laterOrEqual(this.currentPeriod)
#       return this.previousPeriod
#     else
#       return null
# 
# 
#   # Sets the link from this period to the next. This period is automatically added as the predecessor to the next period.
#   setNextPeriod: (period) ->
#     this.nextPeriod = period
#     
#     period.previousPeriod = this if (period)
# 
# 
#   getNextPeriod: ->
#     return this.nextPeriod
# 
#   getCurrentPeriod: ->
#     return this.currentPeriod
# 
# 
#   # Adds a course to the list of courses that are arranged on this period.
#   addCourseInstance: (courseInstance) ->
#     this.courseInstances[courseInstance.getCourse().getCode()] = courseInstance
# 
# 
#   # Puts a course on this period.
#   addCourse: (course, slot) ->
#     this.courses[course.getCode()] = course
#     
#     length = course.getLength()  # Length in periods
#     
#     # Check that the slot is free. Find a free slot if it's occupied.
#     if !slot || !this.isSlotFree(slot, length)
#       slot = this.findFreeSlot(length)
#   
#     
#     # Occupy slots
#     this.occupySlot(slot, length, course)
#     course.setSlot(slot)
#     
#     # Update credits
#     this.updateCredits()
# 
# 
#   updateCredits: ->
#     credits = 0
#     for (array_index in this.courses)
#       course = this.courses[array_index]
#       credits += course.getCredits()
#     
#     this.credits_element.html(credits)
# 
# 
#   removeCourse: (course) ->
#     # Remove course from the list
#     delete this.courses[course.getCode()]
#     
#     # Free slots
#     this.freeSlot(course.getSlot(), course.getLength())
#     
#     # Update credits
#     this.updateCredits()
# 
# 
# 
#   # Returns true if the given course has an instance available on this period.
#   courseAvailable: (course) ->
#     return this.courseInstances[course.getCode()]?
# 
# 
#   findFreeSlot: (length) ->
#     for(slot = 0; slot < 100; slot++)
#       if this.isSlotFree(slot, length)
#         return slot
# 
# 
#   # Returns true if the given slot is free on this and the given number of succeeding periods.
#   isSlotFree: (slot, length) ->
#     return false if this.slots[slot]
#     
#     if !this.nextPeriod || length <= 1
#       return true
#     else
#       return this.nextPeriod.isSlotFree(slot, length - 1)
# 
# 
#   # Occupies slots in this and succeeding periods.
#   # @param slot The slot to be freed.
#   # @param length How many periods to span
#   # @param course Course that occupies the slot.
#   occupySlot: (slot, length, course) ->
#     this.slots[slot] = course
#     
#     return if (length <= 1 || !this.nextPeriod)
#     
#     this.nextPeriod.occupySlot(slot, length - 1, course)
# 
# 
#   # Frees slots in this and succeeding periods.
#   # @param slot The slot to be freed.
#   # @param length How many periods to span
#   freeSlot: (slot, length) ->
#     this.slots[slot] = false
#     
#     return if (length <= 1 || !this.nextPeriod)
#     
#     this.nextPeriod.freeSlot(slot, length - 1)
# 
# 
#   #  Decides whether droppable should accept given draggable.
# 
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
#   courseDropped(event, ui) ->
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
