
@module 'O4', ->
  @module 'skillEditor', ->

    LocalizedDescription = O4.skillEditor.LocalizedDescription

    class @Skill

      # Class method #
      #
      # Function that returns the DOMElement to be displayed while dragging a skill.
      @createDragHelperElement: (event, skillElement) ->
        # Clone the element and add a class that enables 'move' cursor
        $(skillElement).clone().removeAttr('id').addClass("dragging-skill")

      # Class method #
      #
      # We need to use a class method here, because the knockout binding handler for
      # jQuery-sortable makes it hard to bind an instance method to the 'afterMove' 
      # callback.
      @afterSkillMoved: (moveDetails, event) ->
        moveDetails.item.saveUpdatedPosition(moveDetails.targetIndex)

      constructor: (@editor, node, data) ->
        @node = node
        @id = ko.observable(false)
        @icon = false
        @descriptions = ko.observableArray()
        @localizedDescription = ko.observable('untitled')
        @selected = ko.observable(false)
        #@highlighted = ko.observable(false)
        @isLoading = ko.observable(false)
        @isBeingDeleted = ko.observable(false)
        
        @dynamicIcons = ko.observableArray()  # Icons to show. Array of icon name strings.
        #@prereqToColors = {}  # skill_id => 'color'
        
        # Mapping: skill_id => prereq requirement type (false, 0, or 1)
        @prereqIds = {}
        @prereqTo = []    # Array of Skills
        #@prereqToCount = 0
        
        this.update(data) if data

        # This should be after the Skill data is loaded so that id is set
        @prereqType = ko.computed () =>
          #console.log("Recalculating prereqType for skill id: #{@id()}")
          @editor._currentPrereqIds()[@id()]
      
      update: (data) ->
        @id(data['id'])
        @icon = data['icon']
        @descriptions.removeAll()
        
        missingLocales = {}
        for locale in O4.skillEditor.i18n['required_locales']
          missingLocales[locale] = true

        # Load descriptions
        for description in data['skill_descriptions']
          d = new LocalizedDescription(@editor, description)
          @descriptions.push(d)
          @localizedDescription(d.description()) if d.locale == O4.skillEditor.i18n['current_locale']
          delete missingLocales[description['locale']]    

        # Add descriptions for missing locales
        for locale, value of missingLocales
          @descriptions.push(new LocalizedDescription(@editor, {locale: locale}))
        
        if data['skill_prereqs']
          for prereq in data['skill_prereqs']
            @prereqIds[prereq['prereq_id']] = prereq['requirement']

        if data['prereq_to']
          for prereq in data['prereq_to']
            @prereqTo.push {id: (-> prereq.id), icon: prereq.icon}  # TODO: check this
          
        this.updateIcon()
      
      updateIcon: ->
        icons = {}
        
        if @localizedDescription
          name = @localizedDescription()
        else
          name = @id
        
        for skill in @prereqTo
          continue unless skill.icon
          icons[skill.icon] = true
        
        icons[@icon] = true if @icon
        
        unique_icons = _.keys(icons)
        @dynamicIcons(unique_icons)
      

      dispose: () ->
        # Make sure computed prereqType doesn't leak memory
        @prereqType.dispose()
        @prereqType = undefined
      
      # Saves the Skill to the DB by ajax
      save: (curriculumUrl) ->
        @isLoading(true)
        if @id()
          # Update
          promise = $.ajax
            type: "PUT",
            url: curriculumUrl + '/skills/' + @id(),
            data: { skill: this.toJson() },
            dataType: 'json'
        else
          # Create
          promise = $.ajax
            type: "POST",
            url: curriculumUrl + '/skills',
            data: { skill: this.toJson() },
            dataType: 'json'

        # Common handlers for both cases
        promise.done (data) =>
            @update(data['skill'])
            @isLoading(false)

        promise.fail () =>
          @isLoading(false)
          errorHeading = O4.skillEditor.i18n['saving_skill_failed_heading']
          errorMessage = O4.skillEditor.i18n['saving_skill_failed_message']
          @editor.skillErrorModelView.showErrorMessage(errorHeading, errorMessage)

      saveUpdatedPosition: (newPosition) ->
        promise = $.ajax
          url: @node.editor.curriculumUrl + "/skills/#{@id()}/update_position"
          type: 'PUT'
          data:
            position: newPosition

        promise.done ->
          #console.log("Skill: Successfully updated position")

        promise.fail ->
          #console.log("Skill: saving updated position failed")

      # Remove the node of the skill if the skill is the last prerequirement 
      conditionallyRemoveFromPrereqs: (skill) ->
        prereqNodes = @editor._currentPrereqNodes()
        prereqFound = false
        
        prereqNode = prereqNodes[skill.node.id]
        return unless prereqNode
        
        for skill in prereqNode.skills()
          value = @prereqIds[skill.id()]
          if value == 1 || value == 0
            prereqFound = true
        if not prereqFound
          delete prereqNodes[skill.node.id]

      # Adds skill as the prerequisite of this skill. DB is updated immediately via AJAX
      addPrereq: (skill, requirement) ->
        # Save old state in case we need to roll back
        savedState = @prereqIds[skill.id()]

        # Update new state
        prereqNodes = @editor._currentPrereqNodes()
        @prereqIds[skill.id()] = requirement
        if not prereqNodes[skill.node.id]
          prereqNodes[skill.node.id] = skill.node

        #console.log "AddPrereq: Calling valueHasMutated()"
        @editor._currentPrereqIds.valueHasMutated()
        @editor._currentPrereqNodes.valueHasMutated()

        skill.isLoading(true)
        
        promise = $.ajax
          type: "POST",
          url: "#{@editor.curriculumUrl}/skills/#{@id()}/add_prereq",
          data: {prereq_id: skill.id(), requirement: requirement} # competence_node_id: @node.id, prereq_competence_node_id: skill.node.id

        promise.done () ->
          #console.log("AddPrereq: Succesfully added")
          skill.isLoading(false)
      

        promise.fail (jqXHR, textStatus, error) =>
          #console.log("AddPrereq: Failed: #{textStatus}")

          # Roll back to the state before the action
          @prereqIds[skill.id()] = savedState
          @conditionallyRemoveFromPrereqs(skill)

          #@editor.updatePrereqHighlights()
          @editor._currentPrereqIds.valueHasMutated()
          @editor._currentPrereqNodes.valueHasMutated()

          skill.isLoading(false)
          skill.node.skillErrorOccurred(true)


        
      
      # Removes skill from the prerequisites of this skill. DB is updated immediately via AJAX
      removePrereq: (skill) ->
        # Save state in case we need to rollback
        savedState = @prereqIds[skill.id()]
        delete @prereqIds[skill.id()]
        @conditionallyRemoveFromPrereqs(skill)
        @editor._currentPrereqIds.valueHasMutated()
        @editor._currentPrereqNodes.valueHasMutated()
        
        promise = $.ajax
          type: "POST",
          url: "#{@editor.curriculumUrl}/skills/#{@id()}/remove_prereq",
          data: {prereq_id: skill.id()}

        promise.done () ->
          #console.log("RemovePrereq: Succesfully removed")
          skill.isLoading(false)
        

        promise.fail (jqXHR, textStatus, error) =>
          #console.log("RemovePrereq: Failed: #{textStatus}")

          # Return back to the state before the action
          @prereqIds[skill.id()] = savedState
          #@editor.updatePrereqHighlights()
          @editor._currentPrereqNodes()[skill.node.id] = skill.node
          @editor._currentPrereqIds.valueHasMutated()
          @editor._currentPrereqNodes.valueHasMutated()

          skill.isLoading(false)
          skill.node.skillErrorOccurred(true)

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
        if @node.selectable()  && not @selected() && not @isLoading() && not @isBeingDeleted()
          # Deselect all
          for skill in @node.skills()
            skill.selected(false)

          for node in @editor.visibleNodes()
            for skill in node.skills()
              skill.selected(false)

          # Select this one
          @selected(true)
        @editor.setCurrentlyEditedSkill(this)
        

      clickToggleSupportingPrereq: () ->
        this.togglePrereq(0) unless this.isLoading() || @node.editor.skillBeingDeleted()
        
      clickToggleStrictPrereq: () ->
        this.togglePrereq(1) unless this.isLoading() || @node.editor.skillBeingDeleted()
      
      togglePrereq: (requirement) ->
        targetSkill = @editor.currentlyEditedSkill()
        unless targetSkill
          # TODO: show a hint
          #console.log("togglePrereq: Returning without doing anything since there is no currently edited skill")
          return
        
        # If this is already a prereq, remove it
        if targetSkill.prereqIds[@id()] == requirement
          targetSkill.removePrereq(this)
          
          targetId = targetSkill.id()
          @prereqTo = _.reject @prereqTo, (element) -> element.id() == targetId
          #@prereqType(false)
        
        else # If this is not a prereq, add it
          targetSkill.addPrereq(this, requirement)
          
          @prereqTo.push(targetSkill) if requirement == 1
          #@prereqType(requirement)

        this.updateIcon()

      afterBeingDraggedAndMoved: (details, event) ->
        #console.log("This is a test")

      clickEdit: () ->
        if not @isLoading() && not @isBeingDeleted()
          @editor.openSkillEditor(this)
      
      
      clickDelete: () ->
        if not @isLoading() && not @isBeingDeleted()
          # Make sure this skill is selected
          @clickSelectTarget()
          @editor.showDeletionConfirmationModal(true)

      clickConfirmDeletion: () ->
        return unless @id()
      
        @editor.showDeletionConfirmationModal(false)
        @editor.skillBeingDeleted(true)
        @isBeingDeleted(true)

        promise = $.ajax
          type: "DELETE",
          url: @editor.curriculumUrl + '/skills/' + @id()
        
        promise.done () =>
          # Finally update view
          @node.editor._currentPrereqNodes({})
          @node.editor._currentPrereqIds({})
          @node.skills.remove(this)
          @editor.skillBeingDeleted(false)

        promise.fail (jqXHR, textStatus, error) =>
          #console.log("Skill deletion failed!")
          @editor.skillBeingDeleted(false)
          @isBeingDeleted(false)

          errorHeading = O4.skillEditor.i18n['deletion_failed_heading']
          errorMessage = O4.skillEditor.i18n['deletion_failed_message'](@localizedDescription())
          @editor.skillErrorModelView.showErrorMessage(errorHeading, errorMessage)

      generateDeletionConfirmationString: () ->
        O4.skillEditor.i18n['deletion_confirmation_question'] + " \"#{@localizedDescription()}\"?"
      