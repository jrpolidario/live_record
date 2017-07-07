LiveRecord.Model.create = (config) ->
  config.modelName != undefined || throw new Error('missing :modelName argument')
  config.callbacks != undefined || config.callbacks = {}
  config.plugins != undefined || config.callbacks = {}

  # NEW
  Model = (attributes) ->
    this.attributes = attributes
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

  Model.modelName = config.modelName

  Model.prototype.modelName = ->
    Model.modelName

  Model.prototype.subscribeFromChanges = ->
    # listen for record "update"
    subscription = App['live_record_' + this.modelName() + '_' + this.id()] = App.cable.subscriptions.create({
      channel: 'LiveRecordChannel'
      model_name: this.modelName()
      record_id: this.id()
    },
      connected: ->
        @syncRecord()

      disconnected: ->
        identifier = JSON.parse(this.identifier)
        record = Model.all[identifier.record_id]

        if record.__staleSince == undefined
          record.__staleSince = (new Date()).toISOString()

      received: (data) ->
        identifier = JSON.parse(this.identifier)
        record = Model.all[identifier.record_id]

        switch data.action
          when 'update'
            record.update(data.attributes)

          when 'destroy'
            record.destroy()

      syncRecord: ->
        identifier = JSON.parse(this.identifier)
        record = Model.all[identifier.record_id]

        if record && record.__staleSince != undefined
          @perform(
            'sync_record',
            model_name: identifier.model_name,
            record_id: identifier.record_id,
            stale_since: record.__staleSince
          )
          record.__staleSince = undefined
    )

    this.subscriptions = this.subscriptions.push(subscription)

  Model.prototype.unsubscribeFromChanges = ->
    for subscription in this.subscriptions
      App.cable.subscriptions.remove(subscription)

  # ALL
  Model.all = {}

  # CREATE
  Model.prototype.create = (options) ->
    this._callCallbacks('before:create')

    Model.all[this.attributes.id] = this
    this.subscribeFromChanges()

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

    this.unsubscribeFromChanges()
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
        LiveRecord.plugins[pluginKey].applyToModel(Model, pluginValue)

  # add new Model to collection
  LiveRecord.Model.all[config.modelName] = Model

  Model