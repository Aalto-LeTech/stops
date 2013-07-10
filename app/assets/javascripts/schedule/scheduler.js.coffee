class @Scheduler

  constructor: (@courses) ->
    @schedule = {}   # courseId => period

    for course in @courses
      @schedule[course.id] = course.period


  scheduleUnscheduledCourses: ->
    for course in @courses
      # Skip courses that are already scheduled
      if @schedule[course.id]
        console.log "Skipping #{course.name}. Already scheduled."
        continue

      # Put course after its prereqs (those that have been attached)
      this.postponeAfterPrereqs(course)

      # If course is still unattached, put it on the first period
      unless @schedule[course.id]  #(!period? && !course.unschedulable) || (period && period.earlierThan(period.getCurrentPeriod())
        console.log "#{course.name}. Still unattached. Postponing to current period."
        this.postponeTo(course, Period::currentPeriod)

      # Move forward those courses that depend (recursively) on the newly added course
      this.satisfyPostreqs(course)


  postponeAfterPrereqs: (course) ->
    # Only move if the course has not been locked into its current period
    return if course.locked

    # Find the latest prereq
    latestPeriod = false
    for id,prereq of course.prereqs
      period = @schedule[prereq.id]
      latestPeriod = period if period? && (!latestPeriod || period.laterThan(latestPeriod))

    return unless latestPeriod

    # Put course on the next period after latest prereq
    targetPeriod = latestPeriod.getNextPeriod() || latestPeriod

    # Don't schedule courses before current period
    if targetPeriod.earlierThan(Period::currentPeriod)
      targetPeriod = Period::currentPeriod

    console.log "Postponing #{course.name} to satisfy prereqs."
    this.postponeTo(course, targetPeriod)


  postponeTo: (course, requestedPeriod) ->
    #this.setPeriod(period);

    # If no instances are known for this course, put it on the requested period
    if (course.instanceCount < 1)
      @schedule[course.id] = requestedPeriod
      #this.markUnschedulable()
      return

    period = requestedPeriod
    while (period)
      if course.instancesByPeriodId[period.id]
        @schedule[course.id] = period
        console.log "Move #{course.name} to #{period.name}"
        return

      period = period.getNextPeriod()

    # No period could be found. Put it on the requested period
    console.log "No period found for #{course.name}. Putting on #{period.name}"
    @schedule[course.id] = requestedPeriod
    #this.markUnschedulable()


  satisfyPostreqs: (course) ->
    # Quit recursion if this course is part of an unsolvable chain
    period = @schedule[course.id]
    unless period
      return

    targetPeriod = period.nextPeriod
    unless targetPeriod?
      # Out of periods. Add warning
      # TODO: mark postreqs unschedulable
      return

    # Postpone postreqs that are earlier than this
    for id,other of course.prereqTo
      othersPeriod = @schedule[other.id]
      if !othersPeriod || period.laterOrEqual(othersPeriod)
        console.log "Postponing #{other.name} to #{targetPeriod.name} because it depends on #{course.name}"
        this.postponeTo(other, targetPeriod) unless other.locked
        this.satisfyPostreqs(other)
