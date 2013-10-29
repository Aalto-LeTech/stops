class @CourseHighlighter
  constructor: (data) ->
    return unless data
    
    total_credits = 0
    competences = {}         # competence_node_id => {id: 123, supporting_regex: ''}
    included_courses = {}    # abstract_course_id => Hash
    #courses_by_code = {}    # 'course_code' => Hash
    encountered_courses = {} # abstract_course_id => boolean. Keep track of encountered courses so that credits are never counted twice.
    
    # Load data
    if data['courses']
      for course in data['courses']
        included_courses[course.abstract_course_id] = course
    
    if data['competences']
      for raw_competence in data['competences']
        competences[raw_competence.id] = raw_competence

    # Highlight courses in course tables
    $('.course-table').each ->
      competence_id = $(this).data('competence-id')
      competence = competences[competence_id]
      child_competence_id = $(this).data('child-competence-id')
      child_competence = competences[child_competence_id]
      competence_credits = 0
      
      # Mark courses that are grouped to this competence
      $(this).find('tr').each ->
        abstract_course_id = $(this).data('abstract-course-id')
        return unless abstract_course_id
        course = included_courses[abstract_course_id]
        
        if course
          credits = course.credits || 0
          if course.competence_node_id == competence_id
            $(this).addClass('included-here')
            
            unless encountered_courses[course.abstract_course_id]
              total_credits += credits
              competence_credits += credits
            
            encountered_courses[course.abstract_course_id] = true
          else
            $(this).addClass('included-elsewhere')
        
      # Add supporting courses by regex
      if child_competence && child_competence.supporting_regex
        patt = new RegExp(child_competence.supporting_regex)
        table = $(this).find('tbody')
      
        for abstract_course_id, course of included_courses
          if patt.test(course.abstract_course.code)
            unless encountered_courses[abstract_course_id]
              if course.competence_node_id == competence_id
                credits = course.credits || 0
                total_credits += credits
                competence_credits += credits
                style = 'included-here'
                encountered_courses[course.abstract_course_id] = true
              else
                style = 'included-elsewhere'
            
              table.append($("<tr class='#{style}'><td class='status'><span class='included-here'><i class='icon icon-asterisk'></i></span><span class='included-elsewhere'>&bull;</span></td><td class='course-code'>#{course.abstract_course.code}</td><td class='course-name'></td><td class='course-credits'>#{course.credits}</td><td class='course-period'></td></tr>"))
            
      
      
      $(this).find('span.competence-credits').text(competence_credits)
    
    $('#total-credits').text(total_credits)
    