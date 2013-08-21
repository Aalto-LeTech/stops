class @ModelObject extends BaseObject


  ALL: []
  BYID: {}
  IDC: 1000


  # Constructs the object
  constructor: ->
    @id = ModelObject::IDC
    #dbg.lg("Created #{this}.")
    ModelObject::IDC += 1
    ModelObject::BYID[@id] = this
    ModelObject::ALL.push(this)
    return


  # Renders the object into a string for debugging purposes
  toString: ->
    return "MO[#{@id}]::#{@constructor.name}"
