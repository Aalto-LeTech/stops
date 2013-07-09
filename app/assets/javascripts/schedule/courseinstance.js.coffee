class @CourseInstance
  constructor: (@id, @course, @period, @length) ->

  toString: ->
    "cInst[#{@id}]:{ c:#{@course.id} p:#{@period.id} l:#{@length} }"
