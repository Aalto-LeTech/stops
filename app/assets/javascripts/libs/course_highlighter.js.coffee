class @CourseHighlighter
  constructor: (data) ->
    return unless data
    
    included_courses = {}  # abstract_course_id => Hash
    
    # Load data
    if data['courses']
      for course in data['courses']
        included_courses[course.abstract_course_id] = course

    # Highlight courses in course tables
    $('.course-table tr').each ->
      abstract_course_id = $(this).data('abstract-course-id')
      return unless abstract_course_id
      
      if included_courses[abstract_course_id]
        #$(this).addClass('chosen')
        $(this).find('td.status').append($('<i class="icon icon-asterisk" title="Opintosuunnitelmassa"></i>'))
