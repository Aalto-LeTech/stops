#= require knockout
#= require raphael-min
#= require libs/graph/graphCourse
#= require libs/graph/graphSkill


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
      continue unless rawData.localized_name
      # TODO: load another locale instead

      # Create skill object
      skill = new GraphSkill(rawData.id, rawData.localized_name, this)
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
        skill.addStrictPrereq(prereq) if (prereq)
      
      for prereq_id in rawData.supporting_prereq_ids
        prereq = @skillsById[prereq_id]
        skill.addSupportingPrereq(prereq) if (prereq)

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

  resetSkillHighlights: ->
    for id, skill of @skillsById
      skill.highlighted(false)

  # Initializes visualization
  # available options:
  # 'targetId': id or array of ids.
  #              If set, only courses on the path between the source and the targets are shown.
  #              If not set, all postreq courses are shown recursively.

  # 'postreqSkills': 'all': show all skills of visible postreq courses
  #                  'recursive': follow links
  visualize: (options) ->
    options ||= {}

    # Read target ids
    targetIds = {}         # id => boolean
    if options['targetId']
      if $.isArray(options['targetId'])
        for targetId in options['targetId']
          targetIds[targetId] = true
      else
        targetIds[options['targetId']] = true
    else
      targetIds = false

    # Load source course
    sourceCourse = @coursesById[options['sourceId']]
    unless sourceCourse
      console.log "Course #{options['sourceId']} not found."
      return

    # Show postreq courses
    this.showFuturePaths(sourceCourse, targetIds, options)

    # Show prereq courses recursively, through strict prereqs
    cycleDetector = {}
    sourceCourse.dfs 'backward', 0, cycleDetector, (course, level) ->
      course.visible = true
      course.level = level if course.level == undefined || level < course.level
      GraphCourse::minLevel = course.level if (course.level < GraphCourse::minLevel)

      if 'all' == options['prereqSkills']
        for skill in course.skills
          skill.visible = true

    # Show immediate supporting prereqs
    for id, course of sourceCourse.supportingPrereqsById
      course.visible = true
      course.level = -1 if course.level == undefined
    
    for id, course of sourceCourse.supportingPrereqToById
      course.visible = true
      course.level = 1 if course.level == undefined

    GraphCourse::minLevel = -1 if (GraphCourse::minLevel > -1)
    GraphCourse::maxLevel = 1 if (GraphCourse::maxLevel < 1)

    # Show skills
    for skill in sourceCourse.skills
      skill.visible = true

      for postreq in skill.prereqTo
        postreq.visible = true
        if 'recursive' == options['postreqSkills']
          skill.dfs 'forward', (s, depth) -> s.visible = true

      for prereq in skill.prereqs
        prereq.visible = true
        prereq.course.visible = true

        if 'recursive' == options['prereqSkills']
          skill.dfs 'backward', (s, depth) -> s.visible = true


    this.initializeVisualization(sourceCourse)


  # sets course.visible=true for courses that are on the path beween source and target courses
  # source: Course object
  # targets: hash courseId => true. If targets is not set, all courses are shown recursively
  # options: if 'postreqSkills' == 'all' then all skills are shown
  showFuturePaths: (sourceCourse, targetIds, options) ->
    options ||= {}
    visiting = {}

    dfs = (course, level) ->
      visiting[course.id] = true
      if targetIds
        onPath = targetIds[course.id]
      else
        onPath = true

      # Visit neighbors
      for id, neighbor of course.strictPrereqToById
        continue if visiting[neighbor.id] # Detect cycles
        onPath = dfs(neighbor, level + 1) || onPath

      course.level = level if course.level == undefined || level > course.level
      GraphCourse::maxLevel = course.level if (course.level > GraphCourse::maxLevel)

      if onPath
        course.visible = true

        if 'all' == options['postreqSkills']
          for skill in course.skills
            skill.visible = true
      
      visiting[course.id] = false
      
      return onPath

    dfs(sourceCourse, 0)


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
    @paper = Raphael(@raphaelElement, @levels.length * @levelWidth, @maxHeight)
    #this.paper.setSize(@maxLevel * @levelWidth, @maxHeight);


  createLevels: ->
    levelCount = GraphCourse::maxLevel - GraphCourse::minLevel + 1
    console.log "LevelCount: #{levelCount}"
    @levels = Array(levelCount)

    for i in [0...levelCount]
      @levels[i] = new GraphLevel(i * @levelWidth, @levelWidth)

    # Add courses to Levels
    for id, course of @coursesById
      continue unless course.visible

      course.level -= GraphCourse::minLevel  # Normalize course level numbers so that they start from zero

      @visibleCourses.push(course)
      level = this.levels[course.level]
      level.addCourse(course) if level

    GraphCourse::maxLevel -= GraphCourse::minLevel
    GraphCourse::minLevel = 0


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

    startingCourse.y = (@maxHeight + startingCourse.getElement(this).height()) / 2


    # Set Y indices
    for i in [0...@levels.length]
      @levels[i].setYindicesBackwards()

    for i in [(@levels.length - 1)..0]
      @levels[i].setYindicesForward()

    # Updating positions
    for id,course of @coursesById
      continue unless course.visible
      course.updatePosition()


  hilightCourse: (course) ->
    this.resetSkillHighlights()
    @paper.clear()

    course.drawPrereqArcs()
    course.drawPostreqArcs()
    console.log course.level

    for skill in course.skills
      continue unless skill.visible

      # Hilight all skills
      skill.highlighted(true)
      #skill.drawPostreqArcs(maxLength: 1)
      #skill.drawPrereqArcs(maxLength: 1)

      # Hilight direct prereqs
      for neighbor in skill.prereqs
        neighbor.highlighted(true) if neighbor.course.level < course.level

      # Hilight direct postreqs
      for neighbor in skill.prereqTo
        neighbor.highlighted(true) if neighbor.course.level > course.level


  hilightSkill: (skill) ->
    this.resetSkillHighlights()
    @paper.clear()

    skill.highlighted(true)
    skill.drawPrereqArcs()
    skill.drawPostreqArcs()
    skill.drawSupportingPrereqArcs()
    skill.drawSupportingPostreqArcs()
    
    console.log skill.course.level

    for neighbor in skill.prereqs
      neighbor.highlighted(true) if neighbor.course.level < skill.course.level

    for neighbor in skill.prereqTo
      neighbor.highlighted(true) if neighbor.course.level > skill.course.level

#     skill.dfs 'backward', (s, depth) =>
#       s.highlighted(true)
#       s.drawPrereqArcs()
#
#     skill.dfs 'forward', (s, depth) =>
#       s.highlighted(true)
#       s.drawPostreqArcs()


  createLine: (x1, y1, x2, y2, w, dash) ->
    path = this.paper.path("M"+x1+" "+y1+"L"+x2+" "+y2).attr("stroke", "#888")
    
    path.attr("stroke-dasharray", ". ") if dash #“”, “-”, “.”, “-.”, “-..”, “. ”, “- ”, “--”, “- .”, “--.”, “--..”] 
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
