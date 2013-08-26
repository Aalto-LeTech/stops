# usefulcs.js.coffee
#
# A collection of useful often-needed functions and classes.
#




# Array::merge
#
# Merges two arrays (concatenates in place).
# The function is to avoid Array::concat's often unnecessary creation of a new
# array.


Array::merge = (other) -> Array::push.apply @, other




# clone
#
# Clones (deep copies) anything given to it


clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance




# DelayedCaller
#
# Executes the given function 'call' with the 'object' parameter either
# immediately or with a given delay while making sure that the call is executed
# only once.


class @DelayedCaller

  constructor: (delay, call) ->
    #dbg.lg("DelayedCaller::constructor()...")
    @delay    = delay
    @call     = call
    @callId   = undefined

  immediate: (object) ->
    @callId = undefined
    @call(object)

  delayed: (object, delay=@delay) ->
    callId = new Date().getTime()
    @callId = callId
    setTimeout(
      =>
        if @callId == callId
          @call(object)
      ,
      delay
    )

  cancel: ->
    @callId = undefined
