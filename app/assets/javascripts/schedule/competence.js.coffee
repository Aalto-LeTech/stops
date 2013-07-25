class @Competence

  ALL: []


  createFromJson: (data) ->
    for dat in data
      competence = new Competence(dat)


  constructor: (data) ->
    @isSelected = ko.observable(false)

    @prereqCredits = {}
    @prereqGrades = {}
    @passedCredits = 0
    @totalCredits = 0
    @progressVal = ko.observable()
    @progressWidth = ko.computed =>
      return @progressVal() + '%'

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
      prereq.competences.push(this)
      @prereqs.push(prereq)

      # Update initial values
      grade = prereq.grade()
      credits = prereq.credits()
      @prereqGrades[prereq.scopedId] = grade
      @prereqCredits[prereq.scopedId] = credits
      @totalCredits += credits
      if grade > 0
        @passedCredits += credits

    # Update the progress value
    @progressVal(100 * @passedCredits / @totalCredits)

    # Map the object
    @ALL.push(this)


  # The selected status change handler
  setSelected: (isSelected) ->
    @isSelected(isSelected)

    # Reset highlights
    for prereq in @prereqs
      prereq.hilightPrereq(isSelected)


  updatePrereqCredits: (scopedId, credits) ->
    diff = credits
    diff -= @prereqCredits[scopedId] if @prereqCredits[scopedId] > 0
    if @prereqGrades[scopedId] > 0
      @passedCredits += diff
    @totalCredits += diff
    @prereqCredits[scopedId] = credits
    @progressVal(100 * @passedCredits / @totalCredits)


  updatePrereqGrade: (scopedId, grade) ->
    if @prereqGrades[scopedId] > 0 and not grade > 0
      @passedCredits -= @prereqCredits[scopedId]
    else if not @prereqGrades[scopedId] > 0 and grade > 0
      @passedCredits += @prereqCredits[scopedId]
    @prereqGrades[scopedId] = grade
    @progressVal(100 * @passedCredits / @totalCredits)


  # Renders the object into a string for debugging purposes
  toString: ->
    "com:{ n:#{@name} }"
