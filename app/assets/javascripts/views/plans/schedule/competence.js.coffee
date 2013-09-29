class @Competence

  constructor: () ->
    @isSelected = ko.observable(false)

    @prereqGrades = {}   # planCourseId => integer
    @prereqCredits = {}  # planCourseId => integer
    @passedCredits = 0
    @totalCredits = 0
    @progressVal = ko.observable()
    @progressWidth = ko.computed =>
      return @progressVal() + '%'


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data, coursesByAbstractId) ->
    @name = data['localized_name']
    @id = data['id']

    # Load prereqs
    @prereqs = []
    for abstractId in data['abstract_prereq_ids']
      prereq = coursesByAbstractId[abstractId]
      unless prereq
        console.log("Unknown abstractId #{abstractId}!")
        continue
      prereq.competences.push(this)
      @prereqs.push(prereq)

      # Update initial values
      grade = prereq.grade()
      credits = prereq.credits()
      @prereqGrades[prereq.planCourseId] = grade
      @prereqCredits[prereq.planCourseId] = credits
      @totalCredits += credits
      if grade > 0
        @passedCredits += credits

    # Update the progress value
    @progressVal(100 * @passedCredits / @totalCredits)


  # The selected status change handler
  setSelected: (isSelected) ->
    @isSelected(isSelected)

    # Reset highlights
    for prereq in @prereqs
      prereq.hilightPrereq(isSelected)


  updatePrereqCredits: (planCourseId, credits) ->
    diff = credits
    diff -= @prereqCredits[planCourseId] if @prereqCredits[planCourseId] > 0
    @passedCredits += diff if @prereqGrades[planCourseId] > 0
    @totalCredits += diff
    @prereqCredits[planCourseId] = credits
    @progressVal(100 * @passedCredits / @totalCredits)


  updatePrereqGrade: (planCourseId, grade) ->
    if @prereqGrades[planCourseId] > 0 and not grade > 0
      @passedCredits -= @prereqCredits[planCourseId]
    else if not @prereqGrades[planCourseId] > 0 and grade > 0
      @passedCredits += @prereqCredits[planCourseId]
    @prereqGrades[planCourseId] = grade
    @progressVal(100 * @passedCredits / @totalCredits)


  # Renders the object into a string for debugging purposes
  toString: ->
    "com:{ n:#{@name} }"
