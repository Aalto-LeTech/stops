class @DbObject extends BaseObject


  CLASSES: []
  CLASSMATCHER: {}

  ALL: []
  BYID: {}
  IDC: 1000

  TOASSOC: {}
  ASSOCCED: {}

  LOAD_ERROR_HANDLER: undefined


  # Adds a child class and maps it by its plural names in JS form 'MyObjs' and
  # the general underscore form 'my_objs'
  # Also initializes the 'ALL' and 'BYID' vars.
  addSubClass: (subClass, matchers) ->
    @lg("addSubClass(#{subClass::constructor.name})...")
    subClass::ALL = []
    subClass::BYID = {}
    subClass::HASONE = []
    subClass::HASMANY = []
    subClass::CLASSNAME = subClass::constructor.name                   # MyObj
    subClass::CLASSNAMEP = subClass::CLASSNAME + 's'                   # MyObjs
    subClass::CLASSNAMEVC = subClass::CLASSNAME.toJSVarNameCase()      # myObj
    subClass::CLASSNAMEVCP = subClass::CLASSNAMEVC + 's'               # myObjs
    subClass::CLASSNAMEUC = subClass::CLASSNAME.toUnderscoreNameCase() # my_obj
    subClass::CLASSNAMEUCP = subClass::CLASSNAMEUC + 's'               # my_objs
    if matchers != undefined
      for matcher in matchers
        @CLASSMATCHER[matcher] = subClass
    @CLASSMATCHER[subClass::CLASSNAME] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEP] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEVC] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEVCP] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEUC] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEUCP] = subClass
    @CLASSES.push(subClass)


  # Adds an instance to the class and maps the id.
  addInstance: (instance) ->
    @lg("addInstance(#{instance})...")
    @ALL.push(instance)
    @BYID[instance.id] = instance
    return instance


  # Creates and or updates 1 or more classes' models with the given data.
  #
  # Given the classes Mum, Bar and Foo data in the following form would derive
  # the objects:
  #
  # {
  #   mums: [
  #     { id: 1, foo_id: 1, attr1: 'Foo', attr2: 'Bar' },
  #     ...
  #   ],
  #   bars: [
  #     { id: 1, attr1: 'Foo', attr2: 'Bar' },
  #     ...
  #   ]
  #   ...
  #   foos: [
  #     {
  #       id: 1,
  #       attr1: 'foo',
  #       attr2: 'bar',
  #       mum_ids: [1, 4, ...],
  #       ...
  #     },
  #     ...
  #   ]
  # }
  #
  #
  createFromData: (data) ->
    @lg("createFromData()...")
#    @lg("hash:")
#    console.log(JSON.stringify(data, undefined, 2))
    attrHashArrayHash = data
    instances = @createFromAttrHashArrayHash(attrHashArrayHash)
    @lg("Created #{instances.length} instances!")
    return instances


  # Executes the preceding (createFromData) algorithm with the data received
  # after an AJAX JSON get request to the given url.
  #
  # See the mentioned method to understand the format of the data to receive.
  #
  createFromDataPath: (dataPath, errorHandler=@ajaxErrorHandler) ->
    @ajaxGetJson(
      dataPath,
      @createFromDataPathSuccess,
      errorHandler
    )


  # The success handler -- data forwarder
  createFromDataPathSuccess: (data) ->
    if data
      return @createFromData(data)
    else
      @lgW("No data received!")
      return


  # Creates and or updates 1 or more sub classes' models with the given data.
  #
  # Presumes the received 'attrHashArrayHash' is of the form:
  #
  # attrHashArrayHash = {
  #  MySubClass1: [
  #    { myMySubClassObjectVar1: 'Foo', myMySubClassObjectVar2: 'Bar' },
  #    ...
  #  ]
  #  my_sub_class1: [
  #    { myMySubClassObjectVar1: 'Foo', myMySubClassObjectVar2: 'Bar' },
  #    ...
  #  ]
  #  ...
  # }
  #
  createFromAttrHashArrayHash: (attrHashArrayHash) ->
    @lg("createFromAttrHashArrayHash(z:#{Object.keys(attrHashArrayHash).length})...")
    @lg("Keys: #{JSON.stringify(Object.keys(attrHashArrayHash))}")
    #console.log("data:\n#{JSON.stringify(attrHashArrayHash, undefined, 2)}")
    instances = []
    # Match keys with sub class names and create instances accordingly
    matchedKeys = {}
    for subClassNameKey, subClass of @CLASSMATCHER
      attrHashArray = attrHashArrayHash[subClassNameKey]
      if attrHashArray
        @lg("Matched key '#{subClassNameKey}'! Loading it...")
        instances.merge(subClass::createFromAttrHashArray(attrHashArray))
        matchedKeys[subClassNameKey] = attrHashArray.length
        delete attrHashArrayHash[subClassNameKey]
    # Report the matched keys
    @lgI("Matched #{Object.keys(matchedKeys).length} keys: #{JSON.stringify(matchedKeys)}!")
    # Report the remaining unmatched keys if any
    unmatchedKeys = {}
    for key, value in attrHashArrayHash
      unmatchedKeys[key] = value.length
    if Object.keys(unmatchedKeys).length > 0
      @lgI("Note: Ignoring #{Object.keys(unmatchedKeys).length} unmatched keys: #{JSON.stringify(unmatchedKeys)}!")
    @lg("createFromAttrHashArrayHash(zInstances:#{instances.length})!")
    return instances


  # Creates and or updates the current classes models with the given data
  createFromAttrHashArray: (attrHashArray) ->
    @lg("createFromAttrHashArray(z:#{attrHashArray.length})...")
    instances = []
    for attrHash in attrHashArray
      [instance, isOk] = @createFromAttrHash(attrHash)
      if isOk
        instances.push(@addInstance(instance))
      else
        @lgW("Refusing to add an invalid instance (#{instance})!")
    @lg("createFromAttrHashArray(zInstances:#{instances.length})!")
    return instances


  createFromAttrHash: (attrHash) ->
    instance = new @constructor(attrHash)
    return [instance, instance.id?]


  # Constructs a model and copies the given dict as attributes to the object
  constructor: (arg) ->
    #dbg.lg("Created #{this}.")
    @dboId = DbObject::IDC
    DbObject::IDC += 1
    DbObject::BYID[@dboId] = this
    DbObject::ALL.push(this)
    DbObject::TOASSOC[@dboId] = this
    @id = undefined
    @attrPath = undefined
    @loadedAttrs = {}
    @cachedAttrs = undefined
    @assocs = []
    if arg?
      if typeof arg == 'string'
        attrPath = arg
        @loadAttrsFromPath(attrPath)
      else
        attrHash = arg
        @loadAttrsFromHash(attrHash)


  # Loads the models attributes from the server
  loadAttrsFromPath: (attrPath) ->
    @attrPath = attrPath
    @ajaxGetJson(
      @attrPath,
      @loadAttrsFromPathSuccess
    )


  # Load success handler
  loadAttrsFromPathSuccess: (attrHash) ->
    @loadAttrsFromHash(attrHash)


  # Constructs a model and copies the given dict as attributes to the object
  # NB. Maps attributes in the JS naming convention (foo_bar -> fooBar).
  loadAttrsFromHash: (attrHash) ->
    @lg("loadAttrsFromHash(#{JSON.stringify(attrHash)})...")
    for own attrName, attrValue of attrHash
      attrName = attrName.toJSVarNameCase()
#      if /Ids?$/.test(attrName)
#        if /Id$/.test(attrName)
#          hasOneName = attrName.replace('Id', '')
#          @lg(" + hasOne: #{hasOneName}...")
#          @registerHasOne(hasOneName)
#        else
#          hasManyName = attrName.replace('Ids', '')
#          @lg(" + hasMany: #{hasManyName}...")
#          @registerHasMany(hasManyName)
#      else
#        @lg(" + attr: #{attrName}...")
      this[attrName] = attrValue
      @loadedAttrs[attrName] = attrValue
    @lg("loadedAttrs: #{JSON.stringify(@loadedAttrs)}!")


  # Returns a hash of the loaded attributes with their current values
  attrs: ->
    attrs = {}
    for attrName of @loadedAttrs
      attrs[attrName] = this[attrName]
    return attrs


  # Caches (clones and stores) the attributes that have previously been loaded.
  # NB. Think about how you use this if your attributes include complex objects.
  cacheAttrs: ->
    @cachedAttrs = clone(@attrs())
    return @cachedAttrs


  # Returns whether the attribute with the given name has a different value from
  # the one it had at last cache time.
  # NB. Complex objects always differ since they are cloned.
  isAttrChangedAfterCaching: (attrName) ->
    return this[attrName] != @cachedAttrs[attrName]


  # Returns whether isAttrChangedAfterCaching returns true for any attribute in
  # the given list of attribute names (or in the @loadedAttrs collection).
  isAttrsChangedAfterCaching: (attrNames) ->
    if attrNames == undefined
      attrNames = Object.keys(@loadedAttrs)
    for attrName in attrNames
      return true if @isAttrChangedAfterCaching(attrName)
    return false


  # Renders the objects attributes into a JSON string
  attrsAsJson: ->
    return JSON.stringify(@attrs())


  # Renders the objects assocs into a JSON string
  assocsAsJson: ->
    return JSON.stringify(@assocs)


  # Renders the object into a string for debugging purposes
  toString: ->
    return "DBO[#{@dboId}]::#{@constructor.name}[#{@id}]:{#{@attrsAsJson()} : #{@assocsAsJson()}}"


  # A useful ajax get function
  ajaxGetJson: (path, successHandler, errorHandler=@ajaxErrorHandler) ->
    $.ajax
      type: "GET"
      url: path
      dataType: 'json'
      async: false
      context: this
      success: successHandler
      error: errorHandler


  # Ajax error handler
  ajaxErrorHandler: (errorHash) ->
    if @LOAD_ERROR_HANDLER?
      @LOAD_ERROR_HANDLER(errorHash)




  # The following functions handle the parsing and registeration of associations
  #


  # Parses all assocs or the ones of the given classes
  parseAllAssocs: (arg=undefined) ->
    if arg == undefined
      @lg("bindAllAssocs()...")
      for subClass in @CLASSES
        @parseAllAssocs(subClass)
    else
      subClass = arg
      @lg("bindAllAssocs(#{subClass::CLASSNAME})...")
      subClass::ASSDO = subClass::parseAssocsSub(subClass::HASONE,  '1')
      subClass::ASSDM = subClass::parseAssocsSub(subClass::HASMANY, '*')
      subClass::ASSD = subClass::ASSDO.concat(subClass::ASSDM)


  parseAssocsSub: (arg, assocType) ->
    assdata = []
    return assdata if arg == undefined
    @lg("bindAssocs(#{JSON.stringify(arg)} (#{typeof arg}, #{dbg.type(arg)}, #{arg.length}), #{assocType})...")
    if dbg.type(arg) == 'array'
      @lg("Binding an array of #{assocType} assocs...")
      for ag in arg
        assdata.merge( @parseAssocsSub(ag, assocType) )
      return assdata
    else if typeof arg == 'string'
      assocClassName = arg
      assocVarName = assocClassName.toJSVarNameCase()
      arg = {}
      arg[assocClassName] = assocVarName
      return @parseAssocsSub(arg, assocType)
    else if typeof arg == 'object'
      assocHash = arg
      for assocClassName, arg of assocHash
        if typeof arg == 'string'
          assocVarName = arg
          assocNotNull = false
        else
          assocNotNull = arg['notNull']
          assocVarName = arg['varName']
          if assocVarName == undefined
            assocVarName = assocClassName.toJSVarNameCase()
        @lg("Adding a #{assocType} assoc '#{assocVarName}' towards '#{assocClassName}'...")
        assocClass = @CLASSMATCHER[assocClassName]
        assdata.push({
          'assocType':       assocType
          'assocClassName':  assocClassName
          'assocVarName':    assocVarName
          'assocNotNull':    assocNotNull
          'assocClass':      assocClass
        })
      return assdata
    else
      @lgW("Invalid assoc definition argument (#{JSON.stringify(arg)})!")
      return assdata


  # Binds all assocs or the ones of the given classes
  bindAllAssocs: (dboClass=undefined) ->
    if dboClass == undefined
      @lg("bindAllAssocs()...")
      for subClass in @CLASSES
        @bindAllAssocs(subClass)
    else
      subClass = dboClass
      @lg("bindAllAssocs(#{subClass::CLASSNAME})...")
      subClass::bindAssocs(subClass::ALL)


  # Binds the assocs for 'this'
  bindOwnAssocs: ->
    @bindAssocs([this])


  # Binds all the class' assocs for the given instances
  bindAssocs: (instances) ->
    instances = [instances] if dbg.type(instances) != 'array'
    for instance in instances
      @lg("Assoccing #{instance}...")
      for assd in @ASSD
        assocType       = assd['assocType']
        assocClassName  = assd['assocClassName']
        assocVarName    = assd['assocVarName']
        assocNotNull    = assd['assocNotNull']
        assocClass      = assd['assocClass']
        if assocType == '1'
          assocIdVarName = assocVarName + 'Id'
          id = instance[assocIdVarName]
          if id == undefined
            @lgW("No #{assocIdVarName} found on #{instance} and notNull is #{assocNotNull}!") if assocNotNull
            continue
          assocTarget = assocClass::BYID[id]
          if assocTarget == undefined
            @lgW("Bind target #{assocClassName}[#{id}] does not exist!") if assocNotNull
            continue
          instance[assocVarName] = assocTarget
          instance.addAssoc(assocVarName)
        else
          assocsVarName = assocVarName + 's'
          assocIdsVarName = assocVarName.toJSVarNameCase() + 'Ids'
          if instance[assocsVarName] == undefined
            instance[assocsVarName] = []
          instance.addAssoc(assocsVarName)
          idArray = instance[assocIdsVarName]
          if idArray == undefined
            @lgW("No #{assocIdsVarName} found on #{instance} and notNull is #{assocNotNull}!") if assocNotNull
            continue
          for id in idArray
            assocTarget = assocClass::BYID[id]
            if assocTarget == undefined
              @lgW("Bind target #{assocClassName}[#{id}] does not exist!") if assocNotNull
              continue
            instance[assocsVarName].push(assocTarget)
      if DbObject::ASSOCCED[instance.dboId]
        @lgW("Double assocced instance #{instance}!")
      DbObject::ASSOCCED[instance.dboId] = instance
      delete DbObject::TOASSOC[instance.dboId]



  # Adds an association
  addAssoc: (assocVarName) ->
    if assocVarName in @assocs
      return
    @assocs.push(assocVarName)


  # To offer convenience customization possibilities
#  addTmpAssoc: (assocVarName, assocValue) ->
#    @assocs.push(assocVarName)
#    this[assocVarName] = assocValue


#  # Updates an assiociation
#  setIdO: (obj) ->
#    objVarName = obj.constructor::CLASSNAMEVC
#    objIdVarName = objVarName + 'Id'
#    if not this[objIdVarName]?
#      @lgW("No such association (#{@} -> #{objVarName})! Ignoring request.")
#      return false
#    this[objVarName] = obj
#    this[objIdVarName] = obj.id
#    return obj
