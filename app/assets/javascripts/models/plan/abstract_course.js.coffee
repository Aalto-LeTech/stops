class @AbstractCourse


  VIEWMODEL: undefined

  ALL: []
  BYID: {}


  # Creates and or updates models with the given data
  createFromHashes: (hashes) ->

    dbg.lg("AbstractCourse::createFromHashes()...")

    courses = []
    return courses if not hashes

    for hash in hashes
      if hash.id
        course = @BYID[hash.id]
        if course
          course.loadJson(dat)
        else
          course = new AbstractCourse(hash)
      else
        dbg.lg("AbstractCourse::createFromHashes(): Invalid hash! No id (hash: #{JSON.stringify(hash)}).")

    dbg.lg("AbstractCourse::createFromHashes(): Loaded #{courses.length} courses.")

    return courses


  # Creates the model
  constructor: (data) ->

    @loadJson(data || {})


  # Loads the models core attributes
  loadJson: (hash) ->

    @id            = hash.id
    @code          = hash.code if data.code

    if @id
      @BYID[@id] = this
      @ALL.push(this)
    else
      dbg.lg("AbstractCourse::loadJson(): ERROR: No id!")


  # Resets original values for change detection
  resetOriginals: ->

    @oCode = @code


  # Returns whether the models attributes have been changed
  hasChanged: ->

    return true if @oCode != @code
    return false


  # Renders the object into a string for debugging purposes
  toString: ->

    "AC[#{@id}:#{@code}]"
