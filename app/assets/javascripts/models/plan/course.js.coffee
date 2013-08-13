#= require ./skill


class @Course

  ALL: []
  BYID: {}

  constructor: (data) ->
    @loadJson(data || {})

    @isSelected = ko.observable(false)
    @isPassed   = ko.observable(false)
    @isIncluded = ko.observable(false)


  createFromJson: (data, overwrite=true) ->
    return [] if not data
    courses = []
    # Load courses
    for dat in data
      course = new Course(dat)
      courses.push(course)
      if not @BYID[course.id] or overwrite
        @BYID[course.id] = course
        @ALL.push(course)
    dbg.lg("Loaded #{data.length} courses.")
    return courses


  # Reads some of the model's core attributes from the given JSON data object
  loadJson: (data) ->

    @id      = data.id
    @code    = data.course_code || ''
    @name    = data.localized_name || ''
    @credits = data.credits || 0
    @skills  = Skill::createFromJson(data.skills)
    @path    = data.studyplan_path || ''
    @prereqs = Course::createFromJson(data.prereqs, overwrite=false) || []
    @period  = undefined


  # Renders the object into a string for debugging purposes
  toString: ->
    "c[#{@id}:#{@code} #{@credits} #{dbg.bals([@isSelected()])} #{@period}]"
