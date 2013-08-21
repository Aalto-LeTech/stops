class @BaseObject


  DBG: false
  VIEWMODEL: undefined


  # Prints output to the console
  lg: (msg) ->
    if @DBG then dbg.lg("#{@constructor.name}[#{@id}]::#{msg}")


  # Prints output to the console
  lgI: (msg) ->
    dbg.lg("#{@constructor.name}[#{@id}]::INFO: #{msg}")


  # Prints output to the console
  lgW: (msg) ->
    dbg.lgW("#{@constructor.name}[#{@id}]::WARNING: #{msg}")
    exit()


  # Prints output to the console
  lgE: (msg) ->
    dbg.lgE("#{@constructor.name}[#{@id}]::ERROR: #{msg}")
    exit()
