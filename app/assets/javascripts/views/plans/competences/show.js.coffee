#= require libs/graph/graphView

hilightCourses = ->
  included_courses = {} # abstract_course_id => Hash
  for course in studyplan_summary_data['courses']
    included_courses[course.abstract_course_id] = course
  
  $('.course-table tr').each ->
    abstract_course_id = $(this).data('abstract-course-id')
    return unless abstract_course_id
    
    if included_courses[abstract_course_id]
      #$(this).addClass('chosen')
      $(this).find('td.status').append($('<i class="icon icon-asterisk" title="Opintosuunnitelmassa"></i>'))
    


jQuery ->
  hilightCourses()

  # Show graph
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
      #'supporting': 'show'
      #'prereqSkills': 'recursive'
      'mode': 'dynamic'
    })

    graphView.load(graphPath)
