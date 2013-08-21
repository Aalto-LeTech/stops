class @GraphLevel
  courseMargin: 20

  constructor: (@x, @width) ->
    @courses = []
    @height = 0

  addCourse: (course) ->
    course.x = @x
    @courses.push(course)
  
  getCourses: (course) ->
    return @courses

  updateHeight: (course) ->
    @height = 0

    for course in @courses
      @height += course.getElementHeight() + @courseMargin

    return @height
  

  setYindicesBackwards: () ->
    # Set each course to the barycenter of the forward neighbors
    for course in @courses
      continue unless course.visible
      
      visibleNeighbors = 0

      # Calculate average of the y coordinates of the forward neighbor
      y = 0.0
      for neighbor in course.prereqTo
        continue unless neighbor.visible
        y += neighbor.y
        visibleNeighbors++

      if course.prereqTo.length > 0
        y /= visibleNeighbors
      else
        y = @height / 2.0;

    @distributeCoursesEvenly()
  
  
  setYindicesForward: ->
    # Set each course to the barycenter of the backward neighbors
    for course in @courses
      continue unless course.visible
      
      visibleNeighbors = 0

      # Calculate average of the y coordinates of the backward neighbor
      y = 0.0
      for neighbor in course.prereqs
        continue unless neighbor.visible
        y += neighbor.y
        visibleNeighbors++
      
      if (visibleNeighbors > 0)
        y /= visibleNeighbors
      else
        y = @height / 2.0

    @distributeCoursesEvenly()
  

  distributeCoursesEvenly: ->
    # Sort courses by Y
    @courses.sort((a,b) -> b.y - a.y)

    # Distribute evenly
    #step = (@maxHeight - @height) / (@courses.length - 1)
    # FIXME: maxHeight is a bad name
    y = @maxHeight / 2.0 - @height / 2

    for course in @courses
      course.y = y
      y += course.getElementHeight() + @courseMargin

  

class @GraphCourse
  minLevel: 0
  maxLevel: 0
  
  constructor: (@id, @course_code, @name, @type, @view) ->
    @position = ko.observable({x: 0, y: 0})
    @isCyclic = false
    @level = 0

    @element = undefined
    @x = 0
    @y = 0
    @height = undefined
    @width = undefined

    @skills = []
    @prereqs = []
    @prereqsById = {}
    @prereqTo = []
    @prereqStrength = {}    # course_id => float

    @visible = false


  getElementHeight: ->
    if @type == 'virtual'
      return @courseMargin 
    else
      return @height

  addSkill: (skill) ->
    @skills.push(skill)
  

  # Adds a prereq to this course. Adds this course to the 'prereqTo' list of the other course. Duplicates are ignored.
  addPrereq: (course) ->
    # Don't add duplicates
    return if @prereqsById[course.id]
    
    @prereqsById[course.id] = course
    @prereqs.push(course)
    course.prereqTo.push(this)
  

  #
  # Returns a div.
  #
  getElement: (view) ->
    return if @type == 'virtual'
    return @element if (@element)

    cssClass = ''
    cssClass += ' competence' if @type == 'competence'
    
    if (@cyclic)
      cssClass += ' cyclic'
      @name += "<br />(cyclic prerequisites!)"
    
    div = $('<div class="course' + cssClass + '"><h1>' + @course_code + ' ' + @name + '</h1></div>')
    div.click($.proxy(@click, this))
    @view = view

    ul = $('<ul />')
    div.append(ul)

    for skill in @skills
      skill.view = view
      li = $('<li>' + skill.description + '</li>')
      skill.element = li
      ul.append(li)
      li.click($.proxy(skill.click, skill))

    @element = div

    return div
  
  # Updates the position of the element in DOM to match @x, @y
  updatePosition: ->
    pos = @position()
    pos.x = @x
    pos.y = @y
    @position.valueHasMutated()
    
  
  # Draw edges to backward neighbors
  drawPrereqArcs: (options) ->
    options ||= {}
  
    for neighbor in @prereqs
      continue unless (neighbor.element && neighbor.visible)
      continue if options['minLength'] && @level - neighbor.level < options['minLength']
      
      from = @element.position()
      to = neighbor.element.position()

      thickness = (@prereqStrength[neighbor.id] || 0) * 20
      thickness = 1 if thickness < 1
      thickness = 10 if thickness > 10
      
      x1 = to.left + neighbor.element.width()
      y1 = to.top + 10
      x2 = from.left
      y2 = from.top + 10
      
      @view.paper.path("M"+x1+" "+y1+"L"+x2+" "+y2).attr
        'stroke': '#888'
        'stroke-width': thickness
        'arrow-end': 'block-wide'


  # Draw edges to forward neighbors
  drawPostreqArcs: (options) ->
    options ||= {}
  
    for neighbor in @prereqTo
      continue unless (neighbor.element && neighbor.visible)
      continue if options['minLength'] && neighbor.level - @level < options['minLength']
      
      from = @element.position()
      to = neighbor.element.position()
      
      thickness = (neighbor.prereqStrength[@id] || 0) * 20
      thickness = 1 if thickness < 1
      thickness = 10 if thickness > 10

      x1 = from.left + @element.width()
      y1 = from.top + 10
      x2 = to.left
      y2 = to.top + 10
      
      @view.paper.path("M"+x1+" "+y1+"L"+x2+" "+y2).attr
        'stroke': '#888'
        'stroke-width': thickness
        'arrow-end': 'block-wide'
        
  

  # Runs depth-first search in the course graph starting from this course.
  # direction: 'forward' or 'backward'
  # level: keeps track of recursion depth
  # callback: called with (course, level)
  dfs: (direction, level, visiting, callback) ->
    # Visit
    visiting[@id] = true
    callback(this, level) if callback
    
    # Visit neighbors
    if (direction == 'forward')
      container = @prereqTo
      nextLevel = level + 1
    else
      container = @prereqs
      nextLevel = level - 1
    
    for neighbor in container
      # Detect cycles
      if visiting[neighbor.id]
        @isCyclic = true
        continue
      
      neighbor.dfs(direction, nextLevel, visiting, callback)

    visiting[@id] = false
