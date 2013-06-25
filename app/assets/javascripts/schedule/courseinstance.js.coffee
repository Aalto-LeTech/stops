class @CourseInstance
  constructor: (@course, @period, @length, @id) ->

  getId: ->
    return @id

  getCourse: ->
    return @course

  getPeriod: ->
    return @period
