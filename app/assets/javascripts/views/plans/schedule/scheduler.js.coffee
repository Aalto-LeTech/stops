class @Scheduler

  constructor: (@courses, @currentPeriod) ->
    @schedule = {}  # scopedId => period
    @moved = {}     # scopedId => boolean (isMoved?)

    for course in @courses
      @schedule[course.scopedId] = course.period
      @moved[course.scopedId] = false


  scheduleUnscheduledCourses: ->
    for course in @courses
      # Skip courses that are already scheduled
      if @schedule[course.scopedId]
        #console.log "Skipping #{course.name}. Already scheduled."
        continue

      #console.log "Autoscheduling #{course.name}."

      # Put course after its prereqs (those that have been attached)
      this.postponeAfterPrereqs(course)

      # If course is still unattached, put it on the first period
      unless @schedule[course.scopedId]  #(!period? && !course.unschedulable) || (period && period.earlierThan(period.getCurrentPeriod())
        #console.log "#{course.name}. Still unattached. Postponing to current period."
        this.postponeTo(course, @currentPeriod)

      # Move forward those courses that depend (recursively) on the newly added course
      this.satisfyPostreqs(course)


  postponeAfterPrereqs: (course) ->
    # Only move if the course has not been locked into its current period
    return if course.locked

    # Find the latest prereq
    latestPeriod = false
    for scopedId, prereq of course.prereqs
      period = @schedule[prereq.scopedId]
      latestPeriod = period if period? && (!latestPeriod || period.laterThan(latestPeriod))

    return unless latestPeriod

    # Put course on the next period after latest prereq
    targetPeriod = latestPeriod.getNextPeriod() || latestPeriod

    # Don't schedule courses before current period
    if targetPeriod.earlierThan(@currentPeriod)
      targetPeriod = @currentPeriod

    #console.log "Postponing #{course.name} to satisfy prereqs."
    this.postponeTo(course, targetPeriod)


  postponeTo: (course, requestedPeriod) ->
    #this.setPeriod(period);

    # If no instances are known for this course, put it on the requested period
    if (course.instanceCount < 1)
      if @schedule[course.scopedId] != requestedPeriod
        @schedule[course.scopedId] = requestedPeriod
        # Mark course as moved
        @moved[course.scopedId] = true
      #this.markUnschedulable()
      return

    # Since there are instances available, look for the earliest one
    period = requestedPeriod
    while (period)
      # If there is an instance available now, move into it
      if course.instancesByPeriodId[period.id]
        #console.log "Move #{course.name} to #{period.name}"
        if @schedule[course.scopedId] != period
          @schedule[course.scopedId] = period
          # Mark course as moved
          @moved[course.scopedId] = true
        return

      # Otherwise, look further
      period = period.getNextPeriod()

    # No period could be found. Put it on the requested period
    #console.log "No period found for #{course.name}. Putting on #{requestedPeriod.name}."
    if @schedule[course.scopedId] != requestedPeriod
      @schedule[course.scopedId] = requestedPeriod
      # Mark course as moved
      @moved[course.scopedId] = true
    #this.markUnschedulable()


  satisfyPostreqs: (course) ->
    # Quit recursion if this course is part of an unsolvable chain
    period = @schedule[course.scopedId]
    unless period
      return

    targetPeriod = period.nextPeriod
    unless targetPeriod?
      # Out of periods. Add warning
      # TODO: mark postreqs unschedulable
      return

    # Postpone postreqs that are earlier than this
    for scopedId, other of course.prereqTo
      othersPeriod = @schedule[other.scopedId]
      if !othersPeriod || period.laterOrEqual(othersPeriod)
        #console.log "Postponing #{other.name} to #{targetPeriod.name} because it depends on #{course.name}"
        this.postponeTo(other, targetPeriod) unless other.locked
        this.satisfyPostreqs(other)
