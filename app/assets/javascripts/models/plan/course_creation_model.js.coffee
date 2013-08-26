class @CourseCreationModel extends ModelObject
  # Nice and simple


  constructor: () ->
    super()

    @code      = ko.observable()
    @credits   = ko.observable().extend({integer: {min: 0, max: 99}})
    @name      = ko.observable()



  create: ->
    @lg("draft::create()...")


  # Renders the object into a string for debugging purposes
  toString: ->
    return "#{super()}:{#{@code()}}"
