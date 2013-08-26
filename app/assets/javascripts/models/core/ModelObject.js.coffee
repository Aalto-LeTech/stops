class @ModelObject extends BaseObject


  ALL: []
  BYID: {}


  # Constructs the object
  constructor: ->
    super
    ModelObject::BYID[@boId] = this
    ModelObject::ALL.push(this)
    return
