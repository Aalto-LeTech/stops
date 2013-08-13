#= require ./skill
#= require ./prereq


class @Course

  ALL: []

  constructor: (data) ->
    @isSelected = ko.observable(false)

    this.loadJson(data || {})


  resetFromJson: (data) ->
    Skill::clear()
    @ALL.length = 0
    # Load courses
    for dat in data.scoped_courses
      course = new Course(dat)


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    #dbg.lg("#{@}::data: #{JSON.stringify(data)}!")

    @id                  = data.id
    @code                = data.code || ''
    @name                = data.name || ''
    @credits             = data.credits || 0
    @skills              = Skill::createFromJson(data.skills)
    @path                = data.path || ''
    @prereqs             = Prereq::createFromJson(data.prereqs) || []

    @ALL.push(this)


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@id}:#{@code} #{@credits} #{dbg.bals([@isSelected()])}]"
