#= require ./period


class @Plan

  constructor: (path) ->

    return if not path?

    @path = path
    @reload()


  reload: ->
    @coursesByScopedId = {}
    @coursesByAbstractId = {}

    $.ajax
      type: "GET",
      url: @path,
      data: { bundle: 'courses_with_ids_grades_and_periods' }
      context: this,
      dataType: 'json',
      success: @reloadSuccess,
      error: @reloadError,
      async: true


  reloadSuccess: (data) ->

    failed = false

    if not data
      dbg.lg("ERR: No data!")
      failed = true

    if not data.periods?
      dbg.lg("ERR: No period data!")
      failed = true

    if not data.courses?
      dbg.lg("ERR: No course data!")
      failed = true

    if not data.grades?
      dbg.lg("ERR: No grade data!")
      failed = true

    #dbg.lg("data: #{JSON.stringify(data)}!")
    return if failed


    Period::createFromJson(data.periods)

    for course in data.courses
      @coursesByScopedId[course.scoped_course_id] = course
      @coursesByAbstractId[course.abstract_course_id] = course
      period = Period::BYID[course.period_id]
      if period
        course.period = period
      course.grade = 0
    dbg.lg("Loaded #{data.courses.length} plan courses.")

    for grade in data.grades
      @coursesByAbstractId[grade.abstract_course_id].grade = grade.grade
    dbg.lg("Loaded #{data.grades.length} grades.")


  reloadError: (data) ->
    alert('Loading studyplan data failed!')
