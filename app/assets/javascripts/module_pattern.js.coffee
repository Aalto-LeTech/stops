# Simple module pattern for CoffeeScript
# See: http://stackoverflow.com/a/6826293
window.module = (name, fn) ->
  if not @[name]?
    this[name] = {}
  if not @[name].module?
    @[name].module = window.module
  fn.apply this[name]