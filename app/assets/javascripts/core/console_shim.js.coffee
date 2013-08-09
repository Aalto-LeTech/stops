getGlobal = ->
  @

g = getGlobal()

# Ensure console.log doesn't cause errors in Internet Explorer
if typeof g.console == 'undefined' || typeof g.console.log == 'undefined'
  g.console =
    log: ->
      # Do nothing
