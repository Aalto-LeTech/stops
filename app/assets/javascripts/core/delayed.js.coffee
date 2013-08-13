class @DelayedCaller

  constructor: (delay, call) ->
    #dbg.lg("DelayedCaller::constructor()...")
    @delay    = delay
    @call     = call
    @tstamp   = undefined

  immediate: (object) ->
    @tstamp = undefined
    @call(object)

  delayed: (object, delay=@delay) ->
    tstamp = new Date().getTime()
    @tstamp = tstamp
    setTimeout(
      =>
        if @tstamp == tstamp
          @call(object)
      ,
      delay
    )

  cancel: ->
    @tstamp = undefined
