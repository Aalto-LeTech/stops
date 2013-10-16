class @CourseHighlighter
  constructor: (data) ->
    return unless data
    
    total_credits = 0
    included_courses = {}  # abstract_course_id => Hash
    
    # Load data
    if data['courses']
      for course in data['courses']
        included_courses[course.abstract_course_id] = course

    # Highlight courses in course tables
    $('.course-table').each ->
      competence_id = $(this).data('competence-id')
      competence_credits = 0
      
      $(this).find('tr').each ->
        abstract_course_id = $(this).data('abstract-course-id')
        return unless abstract_course_id
        course = included_courses[abstract_course_id]
        
        if course
          credits = course.credits || 0
          if course.competence_node_id == competence_id
            $(this).addClass('included-here')
            #$(this).find('td.status').append($('<i class="icon icon-star" title="Opintosuunnitelmassa, ei ryhmitelty tähän"></i>'))
            total_credits += credits
            competence_credits += credits
          else
            $(this).addClass('included-elsewhere')
            #$(this).find('td.status').append($('<i class="icon icon-star-empty" title="Opintosuunnitelmassa"></i>'))
        
        # icon-ok  icon-star  icon-star-empty
      
      $(this).find('.competence-credits').text(competence_credits)
    
    $('#total-credits').text(total_credits)
    