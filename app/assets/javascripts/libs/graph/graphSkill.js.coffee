class @GraphSkill

  constructor: (@id, @name, @view) ->
    @course = false

    @element = undefined
    @x = 0
    @y = 0
    @height = undefined
    @width = undefined
    
    @prereqs = []
    @prereqTo = []
    @strictPrereqs = []
    @strictPrereqTo = []
    @supportingPrereqs = []
    @supportingPrereqTo = []
    
    @highlighted = ko.observable(false)
    @visible = ko.observable(false)
    
  updateElementDimensions: (element) ->
    @element = element if (element)
    return unless @element
    
    @width = @element.width()
    @height = @element.height()

  setCourse: (course) ->
    @course = course
  

  addStrictPrereq: (prereq) ->
    @prereqs.push(prereq)
    @strictPrereqs.push(prereq)
    prereq.prereqTo.push(this)
    prereq.strictPrereqTo.push(this)
    
    @course.addStrictPrereq(prereq.course)
    
    @course.prereqStrength[prereq.course.id] ||= 0.0
    @course.prereqStrength[prereq.course.id] += 1.0
  
  addSupportingPrereq: (prereq) ->
    @prereqs.push(prereq)
    @supportingPrereqs.push(prereq)
    prereq.prereqTo.push(this)
    prereq.supportingPrereqTo.push(this)
    
    @course.addSupportingPrereq(prereq.course)
    
    @course.prereqStrength[prereq.course.id] ||= 0.0
    @course.prereqStrength[prereq.course.id] += 1.0

  
  # Draw edges to backward neighbors
  drawPrereqArcs: (options) ->
    options ||= {}
  
    for neighbor in @strictPrereqs
      continue unless (neighbor.element && neighbor.visible() && neighbor.course.visible)
      continue if options['maxLength'] && @course.level - neighbor.course.level > options['maxLength']
      continue if @course.level <= neighbor.course.level
      
      from = @element.position()
      to = neighbor.element.position()
      
      @view.createLine(
        from.left + @course.x,
        from.top + @course.y + @element.height() / 2,
        to.left + neighbor.course.x + neighbor.element.width(),
        to.top + neighbor.course.y + neighbor.element.height() / 2,
        1, false)
  
  drawSupportingPrereqArcs: (options) ->
    options ||= {}

    for neighbor in @supportingPrereqs
      continue unless (neighbor.element && neighbor.visible() && neighbor.course.visible)
      continue if options['maxLength'] && @course.level - neighbor.course.level > options['maxLength']
      continue if @course.level <= neighbor.course.level
      
      from = @element.position()
      to = neighbor.element.position()
      
      @view.createLine(
        from.left + @course.x,
        from.top + @course.y + @element.height() / 2,
        to.left + neighbor.course.x + neighbor.element.width(),
        to.top + neighbor.course.y + neighbor.element.height() / 2,
        1, true)


  # Draw edges to forward neighbors
  drawPostreqArcs: (options) ->
    options ||= {}
    
    for neighbor in @strictPrereqTo
      continue unless (neighbor.element && neighbor.visible() && neighbor.course.visible)
      continue if options['maxLength'] && neighbor.course.level - @course.level > options['maxLength']
      continue if @course.level >= neighbor.course.level
      
      from = @element.position()
      to = neighbor.element.position()
      
      @view.createLine(
        from.left + @course.x + @element.width(),
        from.top + @course.y + @element.height() / 2,
        to.left + neighbor.course.x,
        to.top + neighbor.course.y + neighbor.element.height() / 2,
        1, false)
  
  # Draw edges to forward neighbors
  drawSupportingPostreqArcs: (options) ->
    options ||= {}
    
    for neighbor in @supportingPrereqTo
      continue unless (neighbor.element && neighbor.visible() && neighbor.course.visible)
      continue if options['maxLength'] && neighbor.course.level - @course.level > options['maxLength']
      continue if @course.level >= neighbor.course.level
      
      from = @element.position()
      to = neighbor.element.position()
      
      @view.createLine(
        from.left + @course.x + @element.width(),
        from.top + @course.y + @element.height() / 2,
        to.left + neighbor.course.x,
        to.top + neighbor.course.y + neighbor.element.height() / 2,
        1, true)

  dfs: (direction, callback) ->
    # Run DFS
    stack = [this]
    visited = {}
    depth = 0
    
    while (stack.length > 0)
      skill = stack.pop()
      continue if visited[skill.id]

      visited[skill.id] = true
      callback(skill, depth)

      if (direction == 'forward')
        container = skill.strictPrereqTo
      else
        container = skill.strictPrereqs
      
      # Add neighbors to stack
      for neighbor in container
        stack.push(neighbor)
      
      depth++
