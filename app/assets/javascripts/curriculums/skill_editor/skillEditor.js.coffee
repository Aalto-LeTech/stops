#= require knockout-2.2.1
#= require knockout-sortable.min
#= require underscore-min
#= require module_pattern
#= require curriculums/skill_editor/knockout_bindings
#= require curriculums/skill_editor/LocalizedDescription
#= require curriculums/skill_editor/SkillViewModel
#= require curriculums/skill_editor/NodeViewModel
#= require curriculums/skill_editor/ErrorViewModel
#= require curriculums/HintViewModel

# Check that i18n strings have been loaded before this file
if not O4.skillEditor.i18n
  throw "skillEditor i18n strings have not been loaded!"


# Boostrap Popover template for skill error messages (adds a close button to the popover)
O4.skillEditor.errorPopoverTemplate = """
                                      <div class="popover closable-popover">
                                        <div class="arrow"></div>
                                        <div class="popover-inner">
                                          <button class="pull-right close">&times;</button>
                                          <h3 class="popover-title"></h3>
                                          <div class="popover-content"></div>
                                        </div>
                                      </div>
                                      """
    
Node                  = O4.skillEditor.Node
Skill                 = O4.skillEditor.Skill
LocalizedDescription  = O4.skillEditor.LocalizedDescription
ErrorViewModel        = O4.skillEditor.ErrorViewModel

@module 'O4', ->
  @module 'skillEditor', ->

    class @CompetenceSkillEditor 
      constructor: (opts) ->
        @i18n = O4.skillEditor.i18n  # Access in the view like this: <span data-bind="text: $root.i18n['qwerty'] ">
        
        @editingAsAPrereq = if opts then !!opts['editAsAPrereq'] else false
        @editingCompetence = if opts then !!opts['editCompetence'] else false
        
        # Observable state
        @node                 = ko.observable()
        @isLoading            = ko.observable(false)
        @loadFailed           = ko.observable(false)
        @searchString         = ko.observable('')
        @searchResults        = ko.observableArray()
        @skillBeingDeleted    = ko.observable(false)
        @targetNodeIsLoading  = ko.observable(true)
        @targetNodeLoadFailed = ko.observable(false)
        @currentlyEditedSkill = ko.observable()       # Skill under editing
        # Internal lookup table to check if a CompetenceNode has skills as prerequirement
        @_currentPrereqNodes  = ko.observable({})
        # Internal lookup table from which skill prereq states are computed automatically
        @_currentPrereqIds    = ko.observable({})
        @showDeletionConfirmationModal = ko.observable(false)

        # Actual observable results to be shown 
        @visibleNodes = ko.computed () =>
          if @searchString().length == 0
            return _.values(@_currentPrereqNodes())
          else
            return @searchResults()  
        
        # Load and initialize some static data
        $targetNode           = $('#target-node')
        @nodeId               = $targetNode.data('node-id')
        @nodeUrl              = $targetNode.data('url')
        @modalDiv             = $('#modal-edit-skill')
        @requiredLocales      = @modalDiv.data('locales').split(',')
        @curriculumUrl        = @modalDiv.data('curriculum-url')
        window.currentLocale  = @modalDiv.data('current-locale')
        
        
        @skillErrorViewModel = new ErrorViewModel
        if @editingCompetence
          hintHidingKey = 'hide_edit_competence_prereqs_help'
        else
          hintHidingKey = if @editingAsAPrereq
            'hide_edit_as_a_prereq_help' 
          else 'hide_edit_prereqs_help'
        @hintViewModel = new O4.misc.HintViewModel hintHidingKey, $('#help-alert')

        ko.applyBindings(this)
        this.loadNode()
      
      
      loadNode: () ->
        
        promise = $.ajax
          url: @nodeUrl,
          dataType: 'json'
            
        promise.done (data) =>
          @targetNodeIsLoading(false)
          @targetNodeLoadFailed(false)
          @node(new Node(this, data))

        promise.fail () =>
          @targetNodeIsLoading(false)
          @targetNodeLoadFailed(true)

      setCurrentlyEditedSkill: (skill) ->
        @currentlyEditedSkill(skill)
        @_currentPrereqIds(skill.prereqIds) # Shares underlying object with the skill
        @updateCurrentPrereqNodes()


      updateCurrentPrereqNodes: () ->

        return if @editingAsAPrereq

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
          @loadFailed(false)

          # At least an empty array is expected
          return unless data
          
          # Got nodes, now process them
          newNodes = @_currentPrereqNodes()
          for result in data
            node = new Node(this, result)
            newNodes[node.id] = node

          # Notify observable of changes
          @_currentPrereqNodes.valueHasMutated()


        promise.fail (jqXHR, textStatus, error) =>
          @isLoading(false)
          @loadFailed(true)

        
      
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
          @loadFailed(false)
          this.parseSearchResults(data)
        promise.fail () => 
          @isLoading(false) 
          @loadFailed(true)
      
      
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
      
      
      # TODO Dead code?
      updatePrereqHighlights: () ->
        # Set highlights
        targetSkill = @currentlyEditedSkill()
        if targetSkill
          for node in @visibleNodes()
            for skill in node.skills()
              skill.prereqType(targetSkill.prereqIds[skill.id()])
      
      
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
          skill.localizedDescription(description.description()) if locale == window.currentLocale
        
        this.openSkillEditor(skill)

      openSkillEditor: (skill) ->
        @currentlyEditedSkill(skill)
        @modalDiv.modal('show')

      # Click save in the modal skill editor
      clickSaveSkill: () ->
        @node().skills.push(@currentlyEditedSkill()) unless @currentlyEditedSkill().id()
        #@currentlyEditedSkill().updateLocalizedDescription()
        @modalDiv.modal('hide')
        
        # save skill by ajax
        @currentlyEditedSkill().save(@curriculumUrl)
          