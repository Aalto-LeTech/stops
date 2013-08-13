#= require libs/graph/graphView

jQuery ->
  element = $('#course-graph')
  coursesPath = element.data('courses-path')
  competencesPath = element.data('competences-path')
  skillsPath = element.data('skills-path')

  graphView = new GraphView(element[0])

  graphView.load(coursesPath, competencesPath, skillsPath)

  graphView.visualize
    'sourceId': element.data('source-id')
    'targetId': element.data('target-id')
    'prereqSkills': 'recursive'
    'postreqSkills': 'recursive'


  # Event handlers
  $(document)
    .on 'click', '.course', (event) ->
      graphView.hilightCourse(ko.dataFor(this))
      event.stopPropagation()
    .on 'click', '.skill', (event) ->
      graphView.hilightSkill(ko.dataFor(this))
      event.stopPropagation()
