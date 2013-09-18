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

  constructor: (@raphaelElement, @visualizationOptions) ->
    @coursesById = {}    # id -> Course object
    @skillsById = {}     # id -> Skill object

    @visibleCourses = []

    @maxHeight = 0  # Height of the highest level
    @paper = undefined    # Raphael paper
    
    # Read target ids
    @targetIds = {}         # id => boolean
    if @visualizationOptions['targetId']
      if $.isArray(@visualizationOptions['targetId'])
        for targetId in @visualizationOptions['targetId']
          @targetIds[targetId] = true
      else
        @targetIds[@visualizationOptions['targetId']] = true
    else
      @targetIds = false


  #load: (coursesPath, competencesPath, skillsPath) ->
  load: (graphPath) ->
    $.ajax
      url: graphPath + '.json',
      context: this,
      dataType: 'json',
      success: (data) =>
        this.parseCourses(data['courses'])
        this.parseCompetences(data['competences'])
        this.parseSkills(data['skills'])
        this.visualize()
        $(@raphaelElement).addClass('animate')

  #
  # Loads courses from JSON data.
  #
  parseCourses: (data) ->
    for rawData in data
      course = new GraphCourse(rawData.id, rawData.course_code, rawData.translated_name, 'course', this)
      @coursesById[rawData.id] = course
      course.isCompetence = false

  #
  # Loads competences from JSON data.
  #
  parseCompetences: (data) ->
    for rawData in data
      course = new GraphCourse(rawData.id, '', rawData.translated_name, 'competence', this)
      @coursesById[rawData.id] = course
      course.isCompetence = true

  #
  # Loads skills from JSON data.
  #
  parseSkills: (data) ->
    # Read JSON
    for rawData in data
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
    for rawData in data
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
  # 'supporting':    'show': show supporting prereqs
  # 'supportingTo':  'show': show courses that the source course supportins
  visualize: (options) ->
    options = @visualizationOptions

    # Load source course
    sourceCourse = @coursesById[options['sourceId']]
    unless sourceCourse
      console.log "Course #{options['sourceId']} not found."
      return

    # Show postreq courses
    this.showFuturePaths(sourceCourse, @targetIds, options)

    # Show prereq courses recursively, through strict prereqs
    cycleDetector = {}
    sourceCourse.dfs 'backward', 0, cycleDetector, (course, level) ->
      course.visible = true
      course.level = level if course.level == undefined || level < course.level
      GraphCourse::minLevel = course.level if course.level < GraphCourse::minLevel

      if 'all' == options['prereqSkills']
        for skill in course.skills
          skill.visible(true)

    # Show immediate supporting prereqs
    if 'show' == options['supporting']
      for id, course of sourceCourse.supportingPrereqsById
        course.visible = true
        course.level = -1 if course.level == undefined
        GraphCourse::minLevel = -1 if GraphCourse::minLevel > -1
    
    if 'show' == options['supportingTo']
      for id, course of sourceCourse.supportingPrereqToById
        if @targetIds
          # Only show supported postreq if it's connected to target. TODO: Only show supported postreq if it's on the path to target
          showCourse = false
          
          for targetId, isTarget of @targetIds
            if course.prereqToById[targetId]
              showCourse = true
              break
        else
          showCourse = true
        
        if showCourse
          course.visible = true
          course.level = 1 if course.level == undefined
          GraphCourse::maxLevel = 1 if GraphCourse::maxLevel < 1

    # Show skills
    for skill in sourceCourse.skills
      skill.visible(true)

      for postreq in skill.prereqTo
        postreq.visible(true) unless 'dynamic' == options['mode']
        if 'recursive' == options['postreqSkills']
          skill.dfs 'forward', (s, depth) -> s.visible(true)

      for prereq in skill.prereqs
        prereq.visible(true) unless 'dynamic' == options['mode']
        #prereq.course.visible = true

        if 'recursive' == options['prereqSkills']
          skill.dfs 'backward', (s, depth) -> s.visible(true)
    
    # Always show target
    if @targetIds
      for targetId, isTarget of @targetIds
        course = @coursesById[targetId]
        unless course.visible
          course.visible = true
          GraphCourse::maxLevel += 1
          course.level = GraphCourse::maxLevel
        
        for skill in course.skills
          skill.visible(true)

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

      if onPath
        course.level = level if course.level == undefined || level > course.level
        GraphCourse::maxLevel = course.level if (course.level > GraphCourse::maxLevel)
        course.visible = true

        if 'all' == options['postreqSkills']
          for skill in course.skills
            skill.visible(true)
      
      visiting[course.id] = false
      
      return onPath

    dfs(sourceCourse, 0)


  initializeVisualization: (startingCourse) ->
    this.createLevels()
    ko.applyBindings(this)
    this.positionCourses(startingCourse)
    @paper = Raphael(@raphaelElement, @levels.length * @levelWidth, @maxHeight)
    #this.paper.setSize(@maxLevel * @levelWidth, @maxHeight);


  createLevels: ->
    levelCount = GraphCourse::maxLevel - GraphCourse::minLevel + 1
    @levels = Array(levelCount)

    for i in [0...levelCount]
      @levels[i] = new GraphLevel(i * @levelWidth, @levelWidth)

    # Add courses to Levels
    for id, course of @coursesById
      continue unless course.visible

      course.level -= GraphCourse::minLevel  # Normalize course level numbers so that they start from zero
      #console.log "#{course.level} #{course.name}"

      @visibleCourses.push(course)
      level = this.levels[course.level]
      level.addCourse(course) if level

    GraphCourse::maxLevel -= GraphCourse::minLevel
    GraphCourse::minLevel = 0


  # This is called by knockout after rendering a course or skill, so that we know the dimensions of the DOM element.
  updateElementDimensions: (elements) ->
    for element in elements
      object = ko.dataFor(element)
      object.updateElementDimensions($(element))

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

    # Update positions
    for id,course of @coursesById
      continue unless course.visible
      course.updatePosition()

  #
  # Refreshes layout
  #
  refreshGraph: ->
    # Calculate level heights
    for level in @levels
      height = level.updateHeight()
      @maxHeight = height if height > @maxHeight

    for level in @levels
      level.maxHeight = @maxHeight
      level.distributeCoursesEvenly()

    # Update positions
    for id,course of @coursesById
      continue unless course.visible
      course.updatePosition()
    
    @paper.setSize(@levels.length * @levelWidth, @maxHeight)


  hilightCourse: (course) ->
    this.resetSkillHighlights()
    @paper.clear()

    if 'dynamic' == @visualizationOptions['mode']
      # Hide all skills
      for level in @levels
        for c in level.courses
          continue if @targetIds && @targetIds[c.id]
          for s in c.skills
            s.visible(false)
      
      # Show skills
      for skill in course.skills
        skill.visible(true)
        
        for postreq in skill.prereqTo
          postreq.visible(true)

        for prereq in skill.prereqs
          prereq.visible(true)
      
      this.refreshGraph()
 
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
 
    if 'dynamic' == @visualizationOptions['mode']
      setTimeout (-> 
        course.drawPrereqArcs()
        course.drawPostreqArcs()
      ), 600
    else
      course.drawPrereqArcs()
      course.drawPostreqArcs()

  hilightSkill: (skill) ->
    this.resetSkillHighlights()
    @paper.clear()

    skill.highlighted(true)
    skill.drawPrereqArcs()
    skill.drawPostreqArcs()
    skill.drawSupportingPrereqArcs()
    skill.drawSupportingPostreqArcs()
    
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
