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
      'after:connect': [],
      'after:disconnect': [],
      'after:reconnect': [],
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
    # listen for record changes (update / destroy)
    subscription = App['live_record_' + this.modelName() + '_' + this.id()] = App.cable.subscriptions.create({
      channel: 'LiveRecordChannel'
      model_name: this.modelName()
      record_id: this.id()
    },
      record: ->
        return @_record if @_record
        identifier = JSON.parse(this.identifier)
        @_record = Model.all[identifier.record_id]

      # on: connect
      connected: ->
        isAReconnect = @record().__staleSince != undefined

        if @record() && isAReconnect
          @syncRecord(@record())

        if isAReconnect
          @record()._callCallbacks('after:reconnect')
        else
          @record()._callCallbacks('after:connect')

      # on: disconnect
      disconnected: ->
        @record().__staleSince = (new Date()).toISOString() unless @record().__staleSince

        @record()._callCallbacks('after:disconnect')

      # on: receive
      received: (data) ->
        @actions[data.action].call(this, data)

      # responds to received() callback above
      actions:
        update: (data) ->
          @record().update(data.attributes)

        destroy: (data) ->
          @record().destroy()

      # syncs local record from remote record
      syncRecord: ->
        @perform(
          'sync_record',
          model_name: @record().modelName(),
          record_id: @record().id(),
          stale_since: @record().__staleSince
        )
        @record().__staleSince = undefined
    )

    this.subscriptions.push(subscription)

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
    'after:connect': [],
    'after:disconnect': [],
    'after:reconnect': [],
    'before:create': [],
    'after:create': [],
    'before:update': [],
    'after:update': [],
    'before:destroy': [],
    'after:destroy': []
  }

  Model.addCallback = Model.prototype.addCallback = (callbackKey, callbackFunction) ->
    index = this._callbacks[callbackKey].indexOf(callbackFunction)
    this._callbacks[callbackKey].push(callbackFunction) if index == -1

  Model.removeCallback = Model.prototype.removeCallback = (callbackKey, callbackFunction) ->
    index = this._callbacks[callbackKey].indexOf(callbackFunction)
    this._callbacks[callbackKey].splice(index, 1) if index != -1

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
    if LiveRecord.plugins
      index =  Object.keys(LiveRecord.plugins).indexOf(pluginKey)
      LiveRecord.plugins[pluginKey].applyToModel(Model, pluginValue) if index != -1

  # add new Model to collection
  LiveRecord.Model.all[config.modelName] = Model

  Model