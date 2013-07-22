class @CourseInstance

  constructor: (@period, @length) ->


  # Renders the object into a string for debugging purposes
  toString: ->
    "cInst:{ p:#{@period} l:#{@length} }"
