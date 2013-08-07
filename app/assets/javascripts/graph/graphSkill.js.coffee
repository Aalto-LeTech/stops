class @GraphSkill

  constructor: (@id, @description) ->
    @element = false
    @course = false
    @visited = false

    @prereqs = []
    @prereqTo = []
    

  setCourse: (course) ->
    @course = course
  

  addPrereq: (prereq) ->
    @prereqs.push(prereq)
    prereq.prereqTo.push(this)
    
    @course.addPrereq(prereq.course)
  

  click: (event) ->
    # Reset hilights and SVG
    @view.resetHilights()
    this.hilight()
    @view.resetVisitedSkills()

    return false
  
  hilight: ->
    this.dfs 'backward', (skill, depth) =>
      skill.element.addClass('hilight')
      skill.visited = true

      # Draw edges to backward neighbors
      for neighbor in skill.prereqs
        continue unless (neighbor.element && neighbor.course.visible)
        from = skill.element.position()
        to = neighbor.element.position()
        
        @view.createLine(
          from.left + skill.course.x,
          from.top + skill.course.y + skill.element.height() / 2,
          to.left + neighbor.course.x + neighbor.element.width(),
          to.top + neighbor.course.y + neighbor.element.height() / 2, 1, false)
    
    @visited = false
    
    this.dfs 'forward', (skill, depth) =>
      skill.element.addClass('hilight')
      skill.visited = true

      # Draw edges to forward neighbors
      for neighbor in skill.prereqTo
        continue unless (neighbor.element && neighbor.course.visible)
        from = skill.element.position()
        to = neighbor.element.position()
        
        @view.createLine(
          from.left + skill.course.x + skill.element.width(),
          from.top + skill.course.y + skill.element.height() / 2,
          to.left + neighbor.course.x,
          to.top + neighbor.course.y + neighbor.element.height() / 2, 1, false)
  
  
  dfs: (direction, callback) ->
    # Run DFS
    stack = [this]
    depth = 0
    
    while (stack.length > 0)
      skill = stack.pop()
      continue if (skill.visited || !skill.element)

      callback(skill, depth)

      if (direction == 'forward')
        container = skill.prereqTo
      else
        container = skill.prereqs
      
      # Add neighbors to stack
      for neighbor in container
        stack.push(neighbor)
      
      depth++
