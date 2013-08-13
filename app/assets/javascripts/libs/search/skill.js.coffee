class @Skill

  ALL: []

  constructor: (data) ->
    this.loadJson(data || {})


  createFromJson: (data) ->
    # Load objects
    skills = []
    for dat in data
      skill = new Skill(dat)
      skills.push(skill)
    return skills


  clear: ->
    @ALL.length = 0


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    @name                = data || ''

    @ALL.push(this)


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@name}]"
