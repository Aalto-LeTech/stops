#= require knockout-2.2.1
#= require raphael-min
#= require graph/graphCourse
#= require graph/graphSkill

class GraphView
  #svgNS: "http://www.w3.org/2000/svg",
  
  constructor: (@element) ->
    @coursesById = {}    # id -> course object
    @skillsById = {}     # id -> skill object
  
    coursesPath = @element.data('courses-path')
    competencesPath = @element.data('competences-path')
    skillsPath = @element.data('skills-path')
    
    @paper = Raphael(document.getElementById('svg'), 100, 100)
    
    this.load(coursesPath, competencesPath, skillsPath)
    this.initializeVisualization(element.data('course-id'))

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
      course = new GraphCourse(rawData.id, rawData.course_code, rawData.translated_name, 'course')
      @coursesById[rawData.id] = course


  #
  # Loads competences from JSON data.
  #
  loadCompetences: (data) ->
    for row in data
      rawData = row.competence

      course = new GraphCourse(rawData.id, '', rawData.translated_name, 'competence');
      @coursesById[rawData.id] = course
      course.setCompetence(true)


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
      skill = new GraphSkill(rawData.id, localized_name)
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
        skill.addPrereq(prereq)  if (prereq)
  

  resetVisitedSkills: ->
    for id, skill of @skillsById
      skill.visited = false
  
  resetVisitedCourses: ->
    for id, course of @coursesById
      course.visited = false

  resetHilights: ->
    $('#course-graph li').removeClass('hilight').removeClass('hilight-strong')
    this.paper.clear()
  
  
  initializeVisualization: (courseId) ->
    targetCourse = @coursesById[courseId]
    return unless targetCourse
    
    # Run through course graph with DFS to
    # - find out which courses are visible
    # - assign courses to levels
    minLevel = 0
    maxLevel = 0
    
    # TODO: make this cleaner
    targetCourse.dfs 'backward', 0, (course, level) ->
      course.visible = true
      course.level = level if (level < course.level)
      minLevel = course.level if (course.level < minLevel)
    
    targetCourse.dfs 'forward', 0, (course, level) ->
      course.visible = true
      course.level = level if (level > course.level)
      maxLevel = course.level if (course.level > maxLevel)
    

    # Create levels
    levelWidth = 600  # TODO: make this constant
    levelCount = maxLevel - minLevel + 1
    @levels = Array(levelCount)
    for i in [0...levelCount]
      # TODO: check if correct number of levels is created
      @levels[i] = new GraphLevel(i * levelWidth, levelWidth)
    

    # Add courses to Levels and the view
    for id, course of @coursesById
      continue unless course.visible
      
      course.level -= minLevel  # Normalize course level numbers so that they start from zero
      
      this.attachCourse(course)
      level = this.levels[course.level]
      level.addCourse(course) if level


    # Calculate level heights
    maxHeight = $(document).height()
    for level in @levels
      height = level.updateHeight()
      maxHeight = height if (height > maxHeight)

    for level in @levels
      level.maxHeight = maxHeight

    targetCourse.y = (maxHeight + targetCourse.getElement(this).height()) / 2  # TODO: does this work?


    # Set Y indices
    for i in [0...@levels.length]
      @levels[i].setYindicesBackwards()

    for i in [(@levels.length - 1)..0]
      @levels[i].setYindicesForward()
    

    # Updating positions
    for id,course of @coursesById
      continue unless course.visible
      course.updatePosition()


    # Update svg size
    #this.paper.setSize($(document).width(), $(document).height());
    this.paper.setSize(levelCount * levelWidth, maxHeight);



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


jQuery ->
  element = $('#course-graph');
  graphView = new GraphView(element)
