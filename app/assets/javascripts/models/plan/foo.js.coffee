class @Foo

  @foome: ->
    console.log("Fooh! #{arg}")
    dbg.lg("Fooh! #{arg}")


  constructor: (arg) ->
    console.log("Hello! #{arg}")
    dbg.lg("Hello! #{arg}")
