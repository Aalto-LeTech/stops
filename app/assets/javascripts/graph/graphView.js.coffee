#= require knockout-2.3.0
#= require raphael-min
#= require graph/graphCourse
#= require graph/graphSkill


# Custom KnockOut binding that makes it possible to move DOM objects.
ko.bindingHandlers.position = {
  update: (element, valueAccessor, bindingHandlers, viewModel) ->
    value = ko.utils.unwrapObservable(valueAccessor())
    
    $(element).css
      left: value.x
      top: value.y
}

class @GraphView
  levelWidth: 600
  
  constructor: (@raphaelElement) ->
    @coursesById = {}    # id -> Course object
    @skillsById = {}     # id -> Skill object
    
    @visibleCourses = []
    
    @minLevel = 0
    @maxLevel = 0
    @maxHeight = 0  # Height of the highest level $(document).height()
    @paper = undefined    # Raphael paper


  load: (coursesPath, competencesPath, skillsPath) -> 
    $.ajax
      url: coursesPath,
      context: this,
      dataType: 'json',
      success: this.loadCourses,
      async: false

    $.ajax
      url: competencesPath,
      context: this,
      dataType: 'json',
      success: this.loadCompetences,
      async: false

    $.ajax
      url: skillsPath,
      context: this,
      dataType: 'json',
      success: this.loadSkills,
      async: false
  
  #
  # Loads courses from JSON data.
  #
  loadCourses: (data) ->
    for row in data
      rawData = row.scoped_course
      course = new GraphCourse(rawData.id, rawData.course_code, rawData.translated_name, 'course', this)
      @coursesById[rawData.id] = course
      course.isCompetence = false

  #
  # Loads competences from JSON data.
  #
  loadCompetences: (data) ->
    for row in data
      rawData = row.competence
      course = new GraphCourse(rawData.id, '', rawData.translated_name, 'competence', this)
      @coursesById[rawData.id] = course
      course.isCompetence = true

  #
  # Loads skills from JSON data.
  #
  loadSkills: (data) ->
    # Read JSON
    for row in data
      rawData = row.skill

      # Skip if skills belongs to a course that is not shown
      course = @coursesById[rawData.competence_node_id]
      continue unless course
      
      # Skip skill if localized text is not available
      continue unless rawData.description_with_locale
      # TODO: load another locale instead
      
      # Create skill object
      localized_name = rawData.description_with_locale.skill_description.description
      skill = new GraphSkill(rawData.id, localized_name, this)
      @skillsById[rawData.id] = skill

      # Add skill to course
      course.addSkill(skill)
      skill.setCourse(course)
    

    # Set connections between skills
    for row in data
      rawData = row.skill
      skill = @skillsById[rawData.id]
      continue unless skill
        
      for prereq_id in rawData.strict_prereq_ids
        prereq = @skillsById[prereq_id]
        skill.addPrereq(prereq) if (prereq)
    
    # Normalize prereq strengths
    for id, course of @coursesById
      for prereqId, strength of course.prereqStrength
        prereq = @coursesById[prereqId]
        possibleConnections = course.skills.length * prereq.skills.length
        if possibleConnections > 0
          strength /= course.skills.length * prereq.skills.length
        else
          strength = 0

        course.prereqStrength[prereqId] = strength
  

  resetVisitedCourses: ->
    for id, course of @coursesById
      course.visited = false

  resetHilights: ->
    # FIXME
    $('#course-graph li').removeClass('hilight').removeClass('hilight-strong')
    this.paper.clear()

  resetSkillHighlights: ->
    for id, skill of @skillsById
      skill.highlighted(false)
  
  visualizeFullGraph: (courseId) ->
    startingCourse = @coursesById[courseId]
    unless startingCourse
      console.log "Course #{courseId} not found."
      return
    
    # Run through course graph with DFS to
    # - assign courses to levels
    # - find out which courses are visible
    minLvl = 0
    maxLvl = 0
    
    startingCourse.dfs 'backward', 0, (course, level) ->
      course.visible = true
      course.level = level if (level < course.level)
      minLvl = course.level if (course.level < minLvl)
    
    startingCourse.dfs 'forward', 0, (course, level) ->
      course.visible = true
      course.level = level if (level > course.level)
      maxLvl = course.level if (course.level > maxLvl)
      
    @minLevel = minLvl
    @maxLevel = maxLvl
    
    this.initializeVisualization(startingCourse)
  
  
  initializeVisualization: (startingCourse) ->
    this.createLevels()
    ko.applyBindings(this)
    this.positionCourses(startingCourse)
    @paper = Raphael(@raphaelElement, @maxLevel * @levelWidth, @maxHeight)
    #this.paper.setSize(@maxLevel * @levelWidth, @maxHeight);

  
  createLevels: ->
    levelCount = @maxLevel - @minLevel + 1
    @levels = Array(levelCount)
    
    for i in [0...levelCount]
      @levels[i] = new GraphLevel(i * @levelWidth, @levelWidth)

    # Add courses to Levels
    for id, course of @coursesById
      continue unless course.visible
      
      course.level -= @minLevel  # Normalize course level numbers so that they start from zero
      
      @visibleCourses.push(course)
      level = this.levels[course.level]
      level.addCourse(course) if level
    
    @maxLevel -= @minLevel
    @minLevel = 0
  
  
  # This is called by knockout after rendering a course or skill, so that we know the dimensions of the DOM element.
  updateElementDimensions: (elements) ->
    for element in elements
      object = ko.dataFor(element)
      el = $(element)
      object.element = el
      object.width = el.width()
      object.height = el.height()
  
  
  positionCourses: (startingCourse) ->
    # Calculate level heights
    for level in @levels
      height = level.updateHeight()
      @maxHeight = height if height > @maxHeight

    for level in @levels
      level.maxHeight = @maxHeight

    startingCourse.y = (@maxHeight + startingCourse.getElement(this).height()) / 2  # TODO: does this work?


    # Set Y indices
    for i in [0...@levels.length]
      @levels[i].setYindicesBackwards()

    for i in [(@levels.length - 1)..0]
      @levels[i].setYindicesForward()
    

    # Updating positions
    for id,course of @coursesById
      continue unless course.visible
      course.updatePosition()


  createLine: (x1, y1, x2, y2, w, color) ->
    this.paper.path("M"+x1+" "+y1+"L"+x2+" "+y2).attr("stroke", "#888")

    # var line = document.createElementNS(this.svgNS, "line");
    #
    # line.setAttributeNS(null, "x1", x1);
    # line.setAttributeNS(null, "y1", y1);
    # line.setAttributeNS(null, "x2", x2);
    # line.setAttributeNS(null, "y2", y2);
    # line.setAttributeNS(null, "stroke-width", w);
    #
    # var color = "rgb(128,128,128)";
    # line.setAttributeNS(null,"stroke",color);
    #
    # this.svg.appendChild(line);


  attachCourse: (course) ->
    courseCanvas = $('#course-graph')
    element = course.getElement(this)
    courseCanvas.append(element)

