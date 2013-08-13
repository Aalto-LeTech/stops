class @Skill

  ALL: []
  BYID: {}

  constructor: (data) ->
    @loadJson(data || {})


  createFromJson: (data) ->
    return [] if not data
    # Load objects
    skills = []
    for dat in data
      skill = new Skill(dat)
      skills.push(skill)
      if not @BYID[skill.id]
        @BYID[skill.id] = skill
        @ALL.push(skill)
    dbg.lg("Loaded #{data.length} skills.")
    return skills


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
