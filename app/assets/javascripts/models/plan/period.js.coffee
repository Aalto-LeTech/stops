class @Period

  ALL: []
  BYID: {}

  constructor: (data) ->
    @loadJson(data || {})


  createFromJson: (data) ->
    return [] if not data
    # Load objects
    periods = []
    for dat in data
      period = new Skill(dat)
      periods.push(period)
      if not @BYID[period.id]
        @BYID[period.id] = period
        @ALL.push(period)
    dbg.lg("Loaded #{data.length} periods.")
    return periods


  clear: ->
    @ALL.length = 0
    @BYID = {}


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    @id      = data.id
    @name    = data.localized_name || ''


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@name}]"
