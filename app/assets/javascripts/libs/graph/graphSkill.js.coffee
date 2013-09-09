class @GraphSkill

  constructor: (@id, @description, @view) ->
    @course = false

    @element = undefined
    @x = 0
    @y = 0
    @height = undefined
    @width = undefined
    
    @prereqs = []
    @prereqTo = []
    
    @supportingPrereqs = []
    @supportingPrereqTo = []
    
    @highlighted = ko.observable(false)
    @visible = false
    

  setCourse: (course) ->
    @course = course
  

  addPrereq: (prereq) ->
    @prereqs.push(prereq)
    prereq.prereqTo.push(this)
    
    @course.addPrereq(prereq.course)
    
    @course.prereqStrength[prereq.course.id] ||= 0.0
    @course.prereqStrength[prereq.course.id] += 1.0
  
  addSupportingPrereq: (prereq) ->
    @supportingPrereqs.push(prereq)
    prereq.supportingPrereqTo.push(this)
    # TODO: affect prereq strength

  
  # Draw edges to backward neighbors
  drawPrereqArcs: (options) ->
    options ||= {}
  
    for neighbor in @prereqs
      continue unless (neighbor.element && neighbor.visible && neighbor.course.visible)
      continue if options['maxLength'] && @course.level - neighbor.course.level > options['maxLength']
      
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
      continue unless (neighbor.element && neighbor.visible && neighbor.course.visible)
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
    
    for neighbor in @prereqTo
      continue unless (neighbor.element && neighbor.visible && neighbor.course.visible)
      continue if options['maxLength'] && neighbor.course.level - @course.level > options['maxLength']
      
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
    
    for neighbor in @prereqTo
      continue unless (neighbor.element && neighbor.visible && neighbor.course.visible)
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
        container = skill.prereqTo
      else
        container = skill.prereqs
      
      # Add neighbors to stack
      for neighbor in container
        stack.push(neighbor)
      
      depth++
