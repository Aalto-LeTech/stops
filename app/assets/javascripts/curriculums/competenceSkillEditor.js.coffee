#= require knockout-2.2.1

class Node
  constructor: (@editor, data) ->
    if data['scoped_course']
      @type = 'scoped_course'
      data = data['scoped_course']
    else if data['competence']
      @type = 'competence'
      data = data['competence']
    else
      throw "Node constructor: data must contain either 'scoped_course' or 'competence'."

    @skills = ko.observableArray()
    
    @id = data['id']
    @code = data['course_code']
    @descriptions = ko.observableArray()
    @localizedName = ko.observable('untitled')
    
    if data['skills']
      for skill in data['skills']
        @skills.push(new Skill(@editor, this, skill))

    if data['course_descriptions']
      for description in data['course_descriptions']
        d = new LocalizedDescription(@editor, description)
        @descriptions.push(d)
        if d.locale == window.currentLocale
          @localizedName(d.name())
    if data['competence_descriptions']
      for description in data['competence_descriptions']
        d = new LocalizedDescription(@editor, description)
        @descriptions.push(d)
        if d.locale == window.currentLocale
          @localizedName(d.description())


class Skill
  constructor: (@editor, node, data) ->
    @node = node
    @id = false
    @descriptions = ko.observableArray()
    @localizedDescription = ko.observable('untitled')
    @selected = ko.observable(false)
    #@highlighted = ko.observable(false)
    @prereqType = ko.observable(false)
    
    @prereqIds = {}
    
    this.update(data) if data
  
  update: (data) ->
    @id = data['id']
    @descriptions.removeAll()
    
    for description in data['skill_descriptions']
      d = new LocalizedDescription(@editor, description)
      @descriptions.push(d)
      @localizedDescription(d.description()) if d.locale == window.currentLocale

    if data['skill_prereqs']
      for prereq in data['skill_prereqs']
        @prereqIds[prereq['prereq_id']] = prereq['requirement']
  
  # Saves the Skill to the DB by ajax
  save: (curriculumUrl) ->
    if @id
      # Update
      $.ajax
        type: "PUT",
        url: curriculumUrl + '/skills/' + @id,
        data: {skill: this.toJson()},
        dataType: 'json',
        success: (data) =>
          this.update(data['skill'])
          
    else
      # Create
      $.ajax
        type: "POST",
        url: curriculumUrl + '/skills',
        data: {skill: this.toJson()},
        dataType: 'json',
        success: (data) =>
          this.update(data['skill'])

  # Adds skill as the prerequisite of this skill. DB is updated immediately via AJAX
  addPrereq: (skill, requirement) ->
    @prereqIds[skill.id] = requirement
    
    $.ajax
      type: "POST",
      url: "#{@editor.curriculumUrl}/skills/#{@id}/add_prereq",
      data: {prereq_id: skill.id, requirement: requirement},
      dataType: 'json'
    
  
  # Removes skill from the prerequisites of this skill. DB is updated immediately via AJAX
  removePrereq: (skill) ->
    @prereqIds[skill.id] = false
    
    $.ajax
      type: "POST",
      url: "#{@editor.curriculumUrl}/skills/#{@id}/remove_prereq",
      data: {prereq_id: skill.id},
      dataType: 'json'

  toJson: () ->
    hash = {competence_node_id: @node.id}
    
    descriptions = []
    hash['skill_descriptions_attributes'] = descriptions
    for description in @descriptions()
      d = description.toJson()
      descriptions.push(d) if d
    
    return hash

  # Click a skill of the target course
  clickSelectTarget: () ->
    # Deselect all
    for skill in @node.skills()
      skill.selected(false)
    
    # Select this one
    @selected(true)
    @editor.currentlyEditedSkill(this)
    @editor.updatePrereqHighlights()
    

  clickToggleSupportingPrereq: () ->
    this.togglePrereq(0)
    
  clickToggleStrictPrereq: () ->
    this.togglePrereq(1)
  
  togglePrereq: (requirement) ->
    targetSkill = @editor.currentlyEditedSkill()
    unless targetSkill
      # TODO: show a hint
      return
    
    # If this is already a prereq, remove it
    if targetSkill.prereqIds[@id] == requirement
      targetSkill.removePrereq(this)
      @prereqType(false)
    
    else # If this is not a prereq, add it
      targetSkill.addPrereq(this, requirement)
      @prereqType(requirement)


  clickEdit: () ->
    @editor.openSkillEditor(this)
  
  
  clickDelete: () ->
    return unless @id
  
    $.ajax
      type: "DELETE",
      url: @editor.curriculumUrl + '/skills/' + @id,
      dataType: 'json'
    
    @node.skills.remove(this)
  

class LocalizedDescription
  constructor: (@editor, data = {}) ->
    @id = data['id']
    @locale = data['locale']
    @name = ko.observable(data['name'] || '')
    @description = ko.observable(data['description'] || '')

  toJson: () ->
    return false if @description().length < 1 && @name().length < 1
    
    hash = {locale: @locale}
    hash['id'] = @id if @id
    hash['description'] = @description() if @description().length > 0
    hash['name'] = @name() if @name().length > 0
    
    return hash


class CompetenceSkillEditor 
  constructor: () ->
    @searchString = ko.observable('')
    @searchResults = ko.observableArray()
    
    @modalDiv = $('#modal-edit-skill')
    @currentlyEditedSkill = ko.observable()    # Skill under editing
    
    window.currentLocale = @modalDiv.data('current-locale')
    @requiredLocales = @modalDiv.data('locales').split(',')
  
    @curriculumUrl = @modalDiv.data('curriculum-url')
    $targetNode = $('#target-node')
    @nodeUrl = $targetNode.data('url')
    @nodeId = $targetNode.data('node-id')
  
    @node = ko.observable()
    ko.applyBindings(this)
    
    this.loadNode()
  
  
  loadNode: () ->
    
    $.ajax
      url: @nodeUrl,
      dataType: 'json',
      success: (data) =>
        @node(new Node(this, data))
    
  
  clickSearch: () ->
    $.ajax
      url: @curriculumUrl + '/search_skills'
      dataType: 'json'
      data: 
        q: @searchString()
        exclude: @nodeId 
      success: (data) => this.parseSearchResults(data)
  
  
  parseSearchResults: (data) ->
    return unless data
  
    @searchResults.removeAll()
  
    # Create nodes
    for result in data
      node = new Node(this, result)
      @searchResults.push(node)
    
    this.updatePrereqHighlights()
  
  updatePrereqHighlights: () ->
    # Set highlights
    targetSkill = @currentlyEditedSkill()
    if targetSkill
      for node in @searchResults()
        for skill in node.skills()
          skill.prereqType(targetSkill.prereqIds[skill.id])
  
  
  clickClearSearch: () ->
    @searchString('')

  searchKeyPress: (data, event) ->
    @clickSearch() if event.which == 13
  
  clickAddSkill: () ->
    skill = new Skill(this, @node())
    for locale in @requiredLocales
      description = new LocalizedDescription(this, {locale: locale})
      skill.descriptions.push(description)
      skill.localizedDescription(description) if locale == window.currentLocale
    
    this.openSkillEditor(skill)

  openSkillEditor: (skill) ->
    @currentlyEditedSkill(skill)
    @modalDiv.modal('show')
  

  # Click save in the modal skill editor
  clickSaveSkill: () ->
    @node().skills.push(@currentlyEditedSkill()) unless @currentlyEditedSkill().id
    #@currentlyEditedSkill().updateLocalizedDescription()
    @modalDiv.modal('hide')
    
    # save skill by ajax
    @currentlyEditedSkill().save(@curriculumUrl)
      
    


jQuery ->
  new CompetenceSkillEditor
