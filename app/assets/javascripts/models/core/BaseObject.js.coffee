class @BaseObject


  CLASSNAME: 'BaseObject'

  DBG: false
  VIEWMODEL: undefined
  I18N: undefined

  IDC: 1


  # Maps a unique ID for each object
  constructor: ->
    @boId = BaseObject::IDC
    BaseObject::IDC += 1


  # Sub classes should override this and return an at least in-class unique ID
  # string, eg. return "[#{@myId}]"
  idS: ->
    return ''


  # Renders the object into a string for debugging purposes
  toString: ->
    return "BO[#{@boId}]::#{@CLASSNAME}#{@idS()}"


  # Prints output to the console
  subLog: (util, msg) ->
    if @boId
      dbg[util]("BO[#{@boId}]::#{@CLASSNAME}#{@idS()}::#{msg}")
    else
      dbg[util]("BO::#{@CLASSNAME}::#{msg}")


  # Prints output to the console
  lg: (msg) ->
    if @DBG then @subLog('lg', "#{msg}")


  # Prints output to the console
  lgI: (msg) ->
    @subLog('lgI', "INFO: #{msg}")


  # Prints output to the console
  lgW: (msg) ->
    @subLog('lgW', "WARNING: #{msg}")
    #exit()


  # Prints output to the console
  lgE: (msg) ->
    @subLog('lgE', "ERROR: #{msg}")
    #exit()
