class @Scheduler

  constructor: (@courses, @currentPeriod) ->
    @schedule = {}  # planCourseId => period
    @moved = {}     # planCourseId => boolean (isMoved?)

    for course in @courses
      @schedule[course.planCourseId] = course.period
      @moved[course.planCourseId] = false


  scheduleUnscheduledCourses: ->
    for course in @courses
      # Skip courses that are already scheduled
      if @schedule[course.planCourseId]
        #console.log "Skipping #{course.name}. Already scheduled."
        continue

      #console.log "Autoscheduling #{course.name}."

      # Put course after its prereqs (those that have been attached)
      this.postponeAfterPrereqs(course)

      # If course is still unattached, put it on the first period
      unless @schedule[course.planCourseId]  #(!period? && !course.unschedulable) || (period && period.earlierThan(period.getCurrentPeriod())
        #console.log "#{course.name}. Still unattached. Postponing to current period."
        this.postponeTo(course, @currentPeriod)

      # Move forward those courses that depend (recursively) on the newly added course
      this.satisfyPostreqs(course)


  postponeAfterPrereqs: (course) ->
    # Only move if the course has not been locked into its current period
    return if course.locked

    # Find the latest prereq
    latestPeriod = false
    for planCourseId, prereq of course.prereqs
      period = @schedule[prereq.planCourseId]
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
      if @schedule[course.planCourseId] != requestedPeriod
        @schedule[course.planCourseId] = requestedPeriod
        @moved[course.planCourseId] = true
      #this.markUnschedulable()
      return

    # Since there are instances available, look for the earliest one
    period = requestedPeriod
    while (period)
      # If there is an instance available now, move into it
      if course.instancesByPeriodId[period.id]
        #console.log "Move #{course.name} to #{period.name}"
        if @schedule[course.planCourseId] != period
          @schedule[course.planCourseId] = period
          @moved[course.planCourseId] = true
        return

      # Otherwise, look further
      period = period.getNextPeriod()

    # No period could be found. Put it on the requested period
    #console.log "No period found for #{course.name}. Putting on #{requestedPeriod.name}."
    if @schedule[course.planCourseId] != requestedPeriod
      @schedule[course.planCourseId] = requestedPeriod
      @moved[course.planCourseId] = true
    
    #this.markUnschedulable()


  satisfyPostreqs: (course) ->
    # Quit recursion if this course is part of an unsolvable chain
    period = @schedule[course.planCourseId]
    unless period
      return

    targetPeriod = period.nextPeriod
    unless targetPeriod?
      # Out of periods. Add warning
      # TODO: mark postreqs unschedulable
      return

    # Postpone postreqs that are earlier than this
    for planCourseId, other of course.prereqTo
      othersPeriod = @schedule[other.planCourseId]
      if !othersPeriod || period.laterOrEqual(othersPeriod)
        #console.log "Postponing #{other.name} to #{targetPeriod.name} because it depends on #{course.name}"
        this.postponeTo(other, targetPeriod) unless other.locked
        this.satisfyPostreqs(other)
