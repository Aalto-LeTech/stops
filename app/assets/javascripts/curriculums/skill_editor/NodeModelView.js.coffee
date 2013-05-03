@module 'O4', ->
  @module 'skillEditor', -> 

    Skill                 = O4.skillEditor.Skill 
    LocalizedDescription  = O4.skillEditor.LocalizedDescription

    class @Node
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

        # Are the skills of this node selectable?
        @selectable = ko.computed () =>
          isTarget = this == @editor.node()
          if (isTarget && not @editor.editingAsAPrereq) || (not isTarget && @editor.editingAsAPrereq)
            true
          else
            false

        @prereqButtonsShown = ko.computed () =>
          isTargetNode = this == @editor.node()
          if (isTargetNode && @editor.editingAsAPrereq) || (not isTargetNode && not @editor.editingAsAPrereq)
            true
          else
            false

        @editButtonsShown = ko.computed () =>
          # Check if node is the target node
          if this == @editor.node()
            true
          else 
            false

        @skillErrorOccurred = ko.observable(false)

        if data['skills']
          for skill in data['skills']
            @skills.push(new Skill(@editor, this, skill))

        if data['course_descriptions']
          descriptionsAsJSON = data['course_descriptions']
        else if data['competence_descriptions']
          descriptionsAsJSON = data['competence_descriptions']

        # Load descriptions
        for description in descriptionsAsJSON
          d = new LocalizedDescription(@editor, description)
          @descriptions.push(d)
          @localizedName(d.name()) if d.locale == O4.skillEditor.i18n['current_locale']
