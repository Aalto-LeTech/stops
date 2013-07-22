class @Competence

  ALL: []


  createFromJson: (data) ->
    for dat in data
      competence = new Competence(dat)


  constructor: (data) ->
    @hilightSelected = ko.observable(false)

    @loadJson(data)


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->
    @name = data['localized_name']

    # Load prereqs
    @prereqs = []
    for prereqId in data['course_ids_recursive']
      prereq = Course::BYSCOPEDID[prereqId]
      unless prereq
        console.log("Unknown prereqId #{prereqId}!")
        continue
      @prereqs.push(prereq)

    # Map the object
    @ALL.push(this)


  # Renders the object into a string for debugging purposes
  toString: ->
    "com:{ n:#{@name} }"
