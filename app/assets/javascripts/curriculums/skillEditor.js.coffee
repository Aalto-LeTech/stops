#= require knockout-2.2.1
#= require underscore-min

# Check that i18n strings have been loaded before this file
if not O4.skillEditor.i18n
  throw "skillEditor i18n strings have not been loaded!"


ko.bindingHandlers.showModal =
  init: (element, valueAccessor) ->
    # Make sure the modal stays hidden once closed
    $(element).on 'hide', () ->
      valueAccessor()(false)

  update: (element, valueAccessor) ->
    value = valueAccessor()
    if ko.utils.unwrapObservable(value)
        $(element).modal('show')
    else 
        $(element).modal('hide')

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
    @localizedType = O4.skillEditor.i18n[@type]

    if data['skills']
      for skill in data['skills']
        @skills.push(new Skill(@editor, this, skill))

    if data['course_descriptions']
      descriptionsAsJSON = data['course_descriptions']
    else if data['competence_descriptions']
      descriptionsAsJSON = data['competence_descriptions']

    for description in descriptionsAsJSON
      d = new LocalizedDescription(@editor, description)
      @descriptions.push(d)
      if d.locale == window.currentLocale
        @localizedName(d.name())


class Skill
  constructor: (@editor, node, data) ->
    @node = node
    @id = false
    @descriptions = ko.observableArray()
    @localizedDescription = ko.observable('untitled')
    @selected = ko.observable(false)
    #@highlighted = ko.observable(false)
    @isLoading = ko.observable(false)
    
    # Mapping: skill_id => prereq requirement type (false, 0, or 1)
    @prereqIds = {}
    
    this.update(data) if data

    # This should be after the Skill data is loaded so that id is set
    @prereqType = ko.computed () =>
      console.log("Recalculating prereqType for skill id: #{@id}")
      @editor._currentPrereqIds()[@id]
  
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

  dispose: () ->
    # Make sure computed prereqType doesn't leak memory
    @prereqType.dispose()
    @prereqType = undefined
  
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

  # Remove the node of the skill if the skill is the last prerequirement 
  conditionallyRemoveFromPrereqs: (skill) ->
    prereqNodes = @editor._currentPrereqNodes()
    prereqFound = false
    for skill in prereqNodes[skill.node.id].skills()
      value = @prereqIds[skill.id]
      if value == 1 || value == 0
        prereqFound = true
    if not prereqFound
      delete prereqNodes[skill.node.id]

  # Adds skill as the prerequisite of this skill. DB is updated immediately via AJAX
  addPrereq: (skill, requirement) ->
    # Save old state in case we need to roll back
    savedState = @prereqIds[skill.id]

    # Update new state
    prereqNodes = @editor._currentPrereqNodes()
    @prereqIds[skill.id] = requirement
    if not prereqNodes[skill.node.id]
      prereqNodes[skill.node.id] = skill.node

    console.log "AddPrereq: Calling valueHasMutated()"
    @editor._currentPrereqIds.valueHasMutated()
    @editor._currentPrereqNodes.valueHasMutated()

    skill.isLoading(true)
    
    promise = $.ajax
      type: "POST",
      url: "#{@editor.curriculumUrl}/skills/#{@id}/add_prereq",
      data: {prereq_id: skill.id, requirement: requirement} # competence_node_id: @node.id, prereq_competence_node_id: skill.node.id

    promise.done () ->
      console.log("AddPrereq: Succesfully added")
      skill.isLoading(false)
  

    promise.fail (jqXHR, textStatus, error) =>
      console.log("AddPrereq: Failed: #{textStatus}")

      # Roll back to the state before the action
      @prereqIds[skill.id] = savedState
      @conditionallyRemoveFromPrereqs(skill)

      #@editor.updatePrereqHighlights()
      @editor._currentPrereqIds.valueHasMutated()
      @editor._currentPrereqNodes.valueHasMutated()

      skill.isLoading(false)

    
  
  # Removes skill from the prerequisites of this skill. DB is updated immediately via AJAX
  removePrereq: (skill) ->
    # Save state in case we need to rollback
    savedState = @prereqIds[skill.id]
    delete @prereqIds[skill.id]
    @conditionallyRemoveFromPrereqs(skill)
    @editor._currentPrereqIds.valueHasMutated()
    @editor._currentPrereqNodes.valueHasMutated()
    
    promise = $.ajax
      type: "POST",
      url: "#{@editor.curriculumUrl}/skills/#{@id}/remove_prereq",
      data: {prereq_id: skill.id}

    promise.done () ->
      console.log("RemovePrereq: Succesfully removed")
      skill.isLoading(false)
    

    promise.fail (jqXHR, textStatus, error) =>
      console.log("RemovePrereq: Failed: #{textStatus}")

      # Return back to the state before the action
      @prereqIds[skill.id] = savedState
      #@editor.updatePrereqHighlights()
      @editor._currentPrereqNodes()[skill.node.id] = node
      @editor._currentPrereqIds.valueHasMutated()
      @editor._currentPrereqNodes.valueHasMutated()

      skill.isLoading(false)

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
    if not @selected()
      # Deselect all
      for skill in @node.skills()
        skill.selected(false)

      # Select this one
      @selected(true)
      @editor.setCurrentlyEditedSkill(this)
    

  clickToggleSupportingPrereq: () ->
    this.togglePrereq(0) unless this.isLoading()
    
  clickToggleStrictPrereq: () ->
    this.togglePrereq(1) unless this.isLoading()
  
  togglePrereq: (requirement) ->
    targetSkill = @editor.currentlyEditedSkill()
    unless targetSkill
      # TODO: show a hint
      console.log("togglePrereq: Returning without doing anything since there is no currently edited skill")
      return
    
    # If this is already a prereq, remove it
    if targetSkill.prereqIds[@id] == requirement
      targetSkill.removePrereq(this)
      #@prereqType(false)

    
    else # If this is not a prereq, add it
      targetSkill.addPrereq(this, requirement)
      #@prereqType(requirement)


  clickEdit: () ->
    @editor.openSkillEditor(this)
  
  
  clickDelete: () ->
    # Make sure this skill is selected
    @clickSelectTarget()
    @editor.showDeletionConfirmationModal(true)

  clickConfirmDeletion: () ->
    return unless @id
  
    @editor.showDeletionConfirmationModal(false)

    promise = $.ajax
      type: "DELETE",
      url: @editor.curriculumUrl + '/skills/' + @id
    
    promise.done () =>
      # Finally update view
      @node.skills.remove(this)

    promise.fail (jqXHR, textStatus, error) =>
      # TODO Failures should be handled
      console.log("Skill deletion failed!")

  generateDeletionConfirmationString: () ->
    O4.skillEditor.i18n['deletion_confirmation_question'] + " \"#{@localizedDescription()}\"?"
  

class LocalizedDescription
  constructor: (@editor, data = {}) ->
    @id = data['id']
    @locale = data['locale']
    @name = ko.observable(data['name'] || '')
    @description = ko.observable(data['description'] || '')
    @localizedLocale = O4.skillEditor.i18n['language_in_' + @locale]

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
    @isLoading = ko.observable(false)
    # Internal lookup table to check if a CompetenceNode has skills as prerequirement
    @_currentPrereqNodes = ko.observable({})
    # Internal lookup table from which skill prereq states are computed automatically
    @_currentPrereqIds = ko.observable({})

    # Actual observable results to be shown 
    @visibleNodes = ko.computed () =>

      console.log("Recomputing visible search result nodes")

      if @searchString().length == 0
        return _.values(@_currentPrereqNodes())
      else
        return @searchResults()  
    
    @modalDiv = $('#modal-edit-skill')
    @showDeletionConfirmationModal = ko.observable(false)
    @currentlyEditedSkill = ko.observable()    # Skill under editing
    
    window.currentLocale = @modalDiv.data('current-locale')
    @requiredLocales = @modalDiv.data('locales').split(',')
  
    @curriculumUrl = @modalDiv.data('curriculum-url')
    $targetNode = $('#target-node')
    @nodeUrl = $targetNode.data('url')
    @nodeId = $targetNode.data('node-id')
    @targetNodeIsLoading = ko.observable(true)
  
    @node = ko.observable()
    ko.applyBindings(this)
    
    this.loadNode()
  
  
  loadNode: () ->
    
    promise = $.ajax
      url: @nodeUrl,
      dataType: 'json'
        
    promise.done (data) =>
      @targetNodeIsLoading(false)
      @node(new Node(this, data))

    promise.fail () =>
      @targetNodeIsLoading(false)

  setCurrentlyEditedSkill: (skill) ->
    @currentlyEditedSkill(skill)
    @_currentPrereqIds(skill.prereqIds) # Shares underlying object with the skill
    @updateCurrentPrereqNodes()
    # @updatePrereqHighlights()


  updateCurrentPrereqNodes: () ->
    currentPrereqs = @_currentPrereqNodes()
    # Current prereq Nodes that are also in the search results must not be included in
    # the skill disposal below. 
    _.each @searchResults(), (node) ->
      if currentPrereqs[node.id]
        delete currentPrereqs[node.id]

    _.each currentPrereqs, (node) ->
      _.each node.skills(), (skill) ->
        skill.dispose()

    @isLoading(true)

    @_currentPrereqNodes({})
    promise = $.ajax
      url: @curriculumUrl + '/competence_nodes/nodes_by_skill_ids'
      dataType: 'json'
      data:
        ids: _.keys(@currentlyEditedSkill().prereqIds)

    promise.done (data) => 
      @isLoading(false)

      # FIXME: Seems that data can be null. Is that a problem?
      unless data
        console.log "CompetenceSkillEditor::updateCurrentPrereqNodes() called with null. Check this."
        return
      
      
      # Got nodes, now process them
      newNodes = @_currentPrereqNodes()
      for result in data
        node = new Node(this, result)
        newNodes[node.id] = node

      # Notify observable of changes
      @_currentPrereqNodes.valueHasMutated()


    promise.fail (jqXHR, textStatus, error) =>
      # TODO What to do when request fails?
      @isLoading(false)

    
  
  clickSearch: () ->
    @isLoading(true)

    promise = $.ajax
      url: @curriculumUrl + '/search_skills'
      dataType: 'json'
      data: 
        q: @searchString()
        exclude: @nodeId 

    promise.done (data) => 
      @isLoading(false)
      this.parseSearchResults(data)
    promise.fail () => @isLoading(false) # TODO Should show error
  
  
  parseSearchResults: (data) ->
    return unless data

    @searchResults.removeAll()
  
    # Get the underlying array so that each 'push' won't trigger dependent observables
    # to be computed.
    searchResults = @searchResults()

    # Create nodes
    for result in data
      node = new Node(this, result)
      searchResults.push(node)

    # Finally, trigger the mutation event
    @searchResults.valueHasMutated()
    
    #this.updatePrereqHighlights()
  
  updatePrereqHighlights: () ->
    # Set highlights
    targetSkill = @currentlyEditedSkill()
    if targetSkill
      for node in @visibleNodes()
        for skill in node.skills()
          skill.prereqType(targetSkill.prereqIds[skill.id])
  
  
  clickClearSearch: () ->
    @searchString('')
    @searchResults.removeAll()

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
