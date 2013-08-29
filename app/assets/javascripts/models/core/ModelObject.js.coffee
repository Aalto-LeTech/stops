class @ModelObject extends BaseObject


  CLASSNAME: 'ModelObject'

  ALL: []
  BYID: {}


  # Constructs the object
  constructor: ->
    super
    ModelObject::BYID[@boId] = this
    ModelObject::ALL.push(this)
    return
