class @GraphLevel

  constructor: (@x, @width) ->
    @courses = []
    @courseMargin = 20  # TODO: make this a constant
    @height = 0

  addCourse: (course) ->
    course.x = @x
    @courses.push(course)
  
  getCourses: (course) ->
    return @courses

  updateHeight: (course) ->
    @height = 0

    for course in @courses
      @height += course.getElementHeight() + @courseMargin   # TODO: add course.getElementHeight()

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
    # FIXME: @maxHeight is not defined
    y = @maxHeight / 2.0 - @height / 2
    #y = @height / 2

    for course in @courses
      course.y = y
      y += course.getElement().height() + @courseMargin

  

class @GraphCourse
  
  constructor: (id, code, name) ->
    @element = false
    @id = id
    @course_code = code
    @name = name
    @isCompetence = false
    @cyclic = false

    @level = 0
    @x = 0
    @y = 0

    @skills = []
    @prereqs = []
    @prereqsById = {}
    @prereqTo = []

    @visible = false
    @visited = false

  getElementHeight: ->
    return this.getElement().height()

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
    return @element if (@element)

    cssClass = if @isCompetence then ' competence' else ''
    
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
  

  setCompetence: (value) ->
    @isCompetence = value
  
  setCyclic: (new_value) ->
    @cyclic = new_value

  # Sets position of the element
  setPosition: (x, y) ->
    @x = x
    @y = y
    @element.css('left', @x)
    @element.css('top', @y)
  
  # Updates the position of the element to match @x, @y
  updatePosition: ->
    @element.css('left', @x)
    @element.css('top', @y)
  

  click: ->
    # Reset hilights and SVG
    @view.resetHilights()
    
    for skill in @skills
      skill.hilight()

    @view.resetVisitedSkills()
  

  # Runs depth-first search in the course graph starting from this course.
  # direction: 'forward' or 'backward'
  # level: keeps track of recursion depth
  # callback: is called with (course, level)
  dfs: (direction, level, callback) ->
    # Visit
    @visited = true
    callback(this, level) if (callback)
    
    # Visit neighbors
    if (direction == 'forward')
      container = @prereqTo
      nextLevel = level + 1
    else
      container = @prereqs
      nextLevel = level - 1
    
    for neighbor in container
      # Detect cycles
      if (neighbor.visited)
        @setCyclic(true)
        neighbor.setCyclic(true)
        continue
      
      neighbor.dfs(direction, nextLevel, callback)
    
    # Backtrack
    @visited = false

