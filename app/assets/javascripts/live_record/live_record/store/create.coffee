LiveRecord.store.create = (config) ->
  config.model != undefined || throw new Error('missing :model argument')
  config.callbacks != undefined || config.callbacks = {}
  config.plugins != undefined || config.callbacks = {}

  modelName = config.model

  # NEW
  Model = (attributes) ->
    this.attributes = attributes
    this.modelName = modelName
    this.subscriptions = []
    # instance callbacks
    this._callbacks = {
      'before:create': [],
      'after:create': [],
      'before:update': [],
      'after:update': [],
      'before:destroy': [],
      'after:destroy': []
    }

    Object.keys(this.attributes).forEach (attribute_key) ->
      if Model.prototype[attribute_key] == undefined
        Model.prototype[attribute_key] = ->
          this.attributes[attribute_key]
    this

  Model.subscribeFromNewRecords = (options) ->
    LiveRecord.subscribeFromNewRecords(modelName, options)

  Model.prototype.subscribeFromChanges = ->
    LiveRecord.subscribeFromChanges(modelName, this.id())

  # ALL
  Model.all = {}

  # CREATE
  Model.prototype.create = (options) ->
    this._callCallbacks('before:create')

    Model.all[this.attributes.id] = this
    subscriptions = this.subscribeFromChanges()
    this.subscriptions = this.subscriptions.concat(subscriptions)

    this._callCallbacks('after:create')
    this

  # UPDATE
  Model.prototype.update = (attributes) ->
    this._callCallbacks('before:update')

    self = this
    Object.keys(attributes).forEach (attribute_key) ->
      self.attributes[attribute_key] = attributes[attribute_key]

    this._callCallbacks('after:update')
    true

  # DESTROY
  Model.prototype.destroy = ->
    this._callCallbacks('before:destroy')

    LiveRecord.removeSubscriptions(this.subscriptions)
    delete Model.all[this.attributes.id]

    this._callCallbacks('after:destroy')
    this

  # CALLBACKS

  ## class callbacks
  Model._callbacks = {
    'before:create': [],
    'after:create': [],
    'before:update': [],
    'after:update': [],
    'before:destroy': [],
    'after:destroy': []
  }

  Model.addCallback = Model.prototype.addCallback = (callbackKey, callbackFunction) ->
    index = this._callbacks[callbackKey].indexOf(callbackFunction)

    if index == -1
      this._callbacks[callbackKey].push(callbackFunction)

  Model.removeCallback = Model.prototype.removeCallback = (callbackKey, callbackFunction) ->
    index = this._callbacks[callbackKey].indexOf(callbackFunction)
    
    if index != -1
      this._callbacks[callbackKey].splice(index, 1)

  Model.prototype._callCallbacks = (callbackKey) ->
    # call class callbacks
    for callback in Model._callbacks[callbackKey]
      callback.call(this)

    # call instance callbacks
    for callback in this._callbacks[callbackKey]
      callback.call(this)

  # AFTER MODEL INITIALISATION

  # add callbacks from arguments
  for callbackKey, callbackFunctions of config.callbacks
    for callbackFunction in callbackFunctions
      Model.addCallback(callbackKey, callbackFunction)


  # enable plugins from arguments
  for pluginKey, pluginValue of config.plugins
    if LiveRecord.plugins != undefined
      index =  Object.keys(LiveRecord.plugins).indexOf(pluginKey)
      if index != -1
        LiveRecord.plugins[pluginKey].applyToModel(Model, modelName, pluginValue)

  Model