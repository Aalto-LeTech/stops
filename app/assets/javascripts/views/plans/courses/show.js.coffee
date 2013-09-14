#= require libs/graph/graphView

jQuery ->
  element = $('#course-graph')
  graphPath = element.data('graph-path')

  if graphPath
    # Event handlers
    $(document)
      .on 'click', '.course', (event) ->
        graphView.hilightCourse(ko.dataFor(this))
        event.stopPropagation()
      .on 'click', '.skill', (event) ->
        graphView.hilightSkill(ko.dataFor(this))
        event.stopPropagation()
    
    graphView = new GraphView(element[0], {
      'sourceId': element.data('source-id')
      'targetId': element.data('target-id')
      'prereqSkills': 'recursive'
      'postreqSkills': 'recursive'
      'supportingTo': 'show'
      'supporting': 'show'
    })

    graphView.load(graphPath)
