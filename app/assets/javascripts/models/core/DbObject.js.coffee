class @DbObject extends BaseObject


  CLASSES: []
  CLASSESBYNAME: {}
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
    subClass::ISSUBCLASS = true
    subClass::ALL = []
    subClass::BYID = {}
    subClass::ASSOCS = []
    # MyObj
    subClass::CLASSNAME = subClass::constructor.name if not subClass::CLASSNAME
    # MyObjs
    subClass::CLASSNAMEP = subClass::CLASSNAME + 's' if not subClass::CLASSNAMEP
    # myObj
    subClass::CLASSNAMEVC = subClass::CLASSNAME.toJSVarNameCase()
    # myObjs
    subClass::CLASSNAMEVCP = subClass::CLASSNAMEP.toJSVarNameCase()
    # my_obj
    subClass::CLASSNAMEUC = subClass::CLASSNAME.toUnderscoreNameCase()
    # my_objs
    subClass::CLASSNAMEUCP = subClass::CLASSNAMEP.toUnderscoreNameCase()

    subClass::ASSOCVNMATCHERS = [
      subClass::CLASSNAMEVC
      subClass::CLASSNAMEVCP
      subClass::CLASSNAME
      subClass::CLASSNAMEP
    ]

    if matchers != undefined
      for matcher in matchers
        @CLASSMATCHER[matcher] = subClass
    @CLASSMATCHER[subClass::CLASSNAME] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEP] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEVC] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEVCP] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEUC] = subClass
    @CLASSMATCHER[subClass::CLASSNAMEUCP] = subClass
    @CLASSESBYNAME[subClass::CLASSNAME] = subClass
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
    super
    #dbg.lg("Created #{this}.")
    DbObject::BYID[@boId] = this
    DbObject::ALL.push(this)
    DbObject::TOASSOC[@boId] = this
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


  # The dbModel ID string
  idS: ->
    return "[#{@id}]"


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
      this[attrName] = attrValue
      @loadedAttrs[attrName] = attrValue
    @lg("loadedAttrs: #{JSON.stringify(@loadedAttrs)}!")




  # Regular attrs
  #


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


  # Returns the changes on attributes since they were last loaded
  getAttrChanges: ->
    changes = []
    for attrName, attrValue in @loadedAttrs
      if this[attrName] != attrValue
        changes.push([attrName, this[attrName]])
    return changes


  # Renders the objects attributes into a JSON string
  attrsAsJson: ->
    return JSON.stringify(@attrs())




  # The following functions handle the parsing and registration of associations
  #


  # Assocs are defined in subclasses as follows:
  #
  #  class @Person extends DbObject
  #    DbObject::addSubClass(Person)
  #
  #  class @Location extends DbObject
  #    DbObject::addSubClass(Location)
  #
  #  class @Country extends DbObject
  #    # In case the used plural form of the class name isn't trivial, specify
  #    # it
  #    CLASSNAMEP: "countries"
  #    DbObject::addSubClass(Country)
  #
  #  Person::ASSOCS =
  #  [
  #    # The basic case:
  #    # [assocVarName, assocTargetClass]
  #    ['father', 'Person']
  #    ['mother', 'Person']
  #
  #    # Here the '*' type is specified explicitely, since only names ending in
  #    # "s" are automatically considered to be of the type:
  #    ['children', 'Person', '*']
  #
  #    # As seen here
  #    ['friends', 'Person']
  #
  #    # Here the name of the related class 'Country' is automagically matched:
  #    'countryOfResidence'
  #
  #    # As it is here
  #    'location'
  #
  #    # General syntax:
  #    ['varName', 'ClassName', args+]
  #
  #    # Supported args include: '1', '*', 'NotNull'
  #  ]


  # Guess target class of an assocVarName
  guessTargetClassOfAssocVarName: (assocVarName) ->
    bestMatch = [undefined, -1]
    for subClass in @CLASSES
      for matcher in subClass::ASSOCVNMATCHERS
        if assocVarName.indexOf(matcher) != -1
          if bestMatch[1] < matcher.length
            bestMatch = [subClass::CLASSNAME, matcher.length]
    return bestMatch[0]


  # Parses all assocs or the ones of the given classes
  parseAllAssocs: (arg=undefined) ->
    if arg == undefined
      @lg("parseAllAssocs()...")
      for subClass in @CLASSES
        @parseAllAssocs(subClass)
    else
      subClass = arg
      #@lg("parseAllAssocs(#{subClass::CLASSNAME})...")
      subClass::ASSD = subClass::parseAssocs()


  # Does the actual parsing
  parseAssocs: ->
    @lg("parseAssocs(#{@ASSOCS?.lenght})...")
    assdata = []
    if not @ASSOCS
      @lg("No assocs defined!")
      return assdata
    if not dbg.type(@ASSOCS) == 'array'
      @lgE("Assocs must be defined in an array!")
      return assdata
    for assocArg in @ASSOCS
      if dbg.type(assocArg) == 'string'
        assocArg = [assocArg]
      if dbg.type(assocArg) == 'array'
        # Does the actual parsing of each assocArg
        # eg. ['mother', 'Person', 'NotNull']
        assocNotNull   = false
        assocType      = undefined
        assocClassName = undefined
        assocVarName   = assocArg[0]
        for arg in assocArg[1..]
          if arg == '1' or arg == '*'
            assocType = arg
          else if arg == 'NotNull'
            assocNotNull = true
          else
            if not assocClassName and @CLASSESBYNAME[arg]
              assocClassName = arg
            if not assocClassName
              @lgW("Ignoring unsupported assocArg '#{arg}'!")
        if not assocClassName
          assocClassName = @guessTargetClassOfAssocVarName(assocVarName)
          if not assocClassName
            @lgE("Could not match '#{assocVarName}' to a class! Ignoring the assoc!")
            continue
        if not assocType
          # Guessing assocType from assocVarName
          if assocVarName.lastChar() == 's' then assocType = '*' else assocType = '1'
        # Determining assocIdVarName
        if assocType == '1'
          assocIdVarName = assocVarName + 'Id'
        else
          if assocVarName.lastChar() == 's'
            assocIdVarName = assocVarName[0..-2] + 'Ids'
          else
            @lgE("Don't know how to singularize #{assocVarName}!")
            continue
        @lg("Adding a #{assocType} assoc '#{assocVarName}' towards '#{assocClassName}'...")
        assocClass = @CLASSESBYNAME[assocClassName]
        assocArgObj =
          'assocVarName':    assocVarName
          'assocIdVarName':  assocIdVarName
          'assocClass':      assocClass
          'assocType':       assocType
          'assocNotNull':    assocNotNull
        assdata.push(assocArgObj)
      else
        @lgE("Invalid assoc definition argument (#{JSON.stringify(assocArg)})!")
        continue
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
      subClass::bindAssocsOn(subClass::ALL)


  # Binds the assocs for 'this'
  bindAssocs: ->
    @bindAssocsOn([this])


  # Binds all the class' assocs for the given instances
  bindAssocsOn: (instances) ->
    if not @ASSD?
      @lgE("Association binding requested before parsing!")
      return
    instances = [instances] if dbg.type(instances) != 'array'
    for assd in @ASSD
      @lg("Assoccing assd #{JSON.stringify(assd)}...")
      assocType       = assd['assocType']
      assocVarName    = assd['assocVarName']
      assocIdVarName  = assd['assocIdVarName']
      assocNotNull    = assd['assocNotNull']
      assocClass      = assd['assocClass']
      assocClassName  = assocClass::CLASSNAME
      for instance in instances
        @lg("Assoccing #{instance}...")
        if not assocVarName in instance.assocs
          instance.assocs.push(assocVarName)
        instance[assocVarName] = undefined
        if assocType == '1'
          id = instance[assocIdVarName]
          if id == undefined
            @lgW("No #{assocIdVarName} found on #{instance} and notNull is #{assocNotNull}!") if assocNotNull
            continue
          assocTarget = assocClass::BYID[id]
          if assocTarget == undefined
            @lgW("Bind target #{assocClassName}[#{id}] does not exist!") if assocNotNull
            continue
          instance[assocVarName] = assocTarget
        else
          idArray = instance[assocIdVarName]
          if idArray == undefined
            @lgW("No #{assocIdVarName} found on #{instance} and notNull is #{assocNotNull}!") if assocNotNull
            continue
          dboArray = []
          for id in idArray
            assocTarget = assocClass::BYID[id]
            if assocTarget == undefined
              @lgW("Bind target #{assocClassName}[#{id}] does not exist!") if assocNotNull
              continue
            dboArray.push(assocTarget)
          instance[assocVarName] = dboArray
    for instance in instances
      if DbObject::ASSOCCED[instance.boId]
        @lgW("Double assocced instance #{instance}!")
      DbObject::ASSOCCED[instance.boId] = instance
      delete DbObject::TOASSOC[instance.boId]


  # Returns the changes on 'this'
  getChanges: ->
    return @getChangesOn([this])


  # Returns the changes for the given instances of this class
  getChangesOn: (instances=@ALL) ->
    instances = [instances] if dbg.type(instances) != 'array'
    for instance in instances
      instance.changes = instance.getAttrChanges()
    for assd in @ASSD
      assocType       = assd['assocType']
      assocVarName    = assd['assocVarName']
      assocIdVarName  = assd['assocIdVarName']
      for instance in instances
        change = undefined
        if assocType == '1'
          if instance[assocIdVarName] != instance[assocVarName]?.id
            change = [assd, instance[assocVarName]?.id]
        else
          oldIds = instance[assocIdVarName]
          newIds = (assocTarget.id for assocTarget in instance[assocVarName])
          addedIds = _.difference(newIds, oldIds)
          removedIds = _.difference(oldIds, newIds)
          if addedIds.length > 0 or removedIds.length > 0
            change = [assd, addedIds, removedIds]
        instance.changes.push(change) if change
    changed = instances.filter (instance) -> instance.changes.length > 0
    return changed


  # Renders the objects assocs into a JSON string
  assocsAsJson: ->
    return JSON.stringify(@assocs)




  # Other methods
  #


  # Renders the object into a string for debugging purposes
  toString: ->
    return "DBO[#{@boId}]::#{@constructor.name}[#{@id}]:{#{@attrsAsJson()} : #{@assocsAsJson()}}"


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
