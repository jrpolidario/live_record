LiveRecord.Model.create = (config) ->
  config.modelName != undefined || throw new Error('missing :modelName argument')
  config.callbacks != undefined || config.callbacks = {}
  config.plugins != undefined || config.callbacks = {}

  # NEW
  Model = (attributes) ->
    this.attributes = attributes
    # instance callbacks
    this._callbacks = {
      'on:connect': [],
      'on:disconnect': [],
      'on:response_error': [],
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

  Model.prototype.subscribe = ->
    return this.subscription if this.subscription != undefined

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
        if @record()._staleSince != undefined
          @syncRecord(@record())

        @record()._callCallbacks('on:connect', undefined)

      # on: disconnect
      disconnected: ->
        @record()._staleSince = (new Date()).toISOString() unless @record()._staleSince
        @record()._callCallbacks('on:disconnect', undefined)

      # on: receive
      received: (data) ->
        if data.error
          @record()._staleSince = (new Date()).toISOString() unless @record()._staleSince
          @onError[data.error.code].call(this, data)
          @record()._callCallbacks('on:response_error', [data.error.code])
          delete @record()['subscription']
        else
          @onAction[data.action].call(this, data)

      # handler for received() callback above
      onAction:
        update: (data) ->
          @record().update(data.attributes)

        destroy: (data) ->
          @record().destroy()

      # handler for received() callback above
      onError:
        forbidden: (data) ->
          console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', @record())
        bad_request: (data) ->
          console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', @record())

      # syncs local record from remote record
      syncRecord: ->
        @perform(
          'sync_record',
          model_name: @record().modelName(),
          record_id: @record().id(),
          stale_since: @record()._staleSince
        )
        @record()._staleSince = undefined
    )

    this.subscription = subscription

  Model.prototype.unsubscribe = ->
    return if this.subscription == undefined
    App.cable.subscriptions.remove(this.subscription)
    delete this['subscription']

  Model.prototype.isSubscribed = ->
    this.subscription != undefined

  # ALL
  Model.all = {}

  # CREATE
  Model.prototype.create = (options) ->
    this._callCallbacks('before:create', undefined)

    Model.all[this.attributes.id] = this
    this.subscribe()

    this._callCallbacks('after:create', undefined)
    this

  # UPDATE
  Model.prototype.update = (attributes) ->
    this._callCallbacks('before:update', undefined)

    self = this
    Object.keys(attributes).forEach (attribute_key) ->
      self.attributes[attribute_key] = attributes[attribute_key]

    this._callCallbacks('after:update', undefined)
    true

  # DESTROY
  Model.prototype.destroy = ->
    this._callCallbacks('before:destroy', undefined)

    this.unsubscribe()
    delete Model.all[this.attributes.id]

    this._callCallbacks('after:destroy', undefined)
    this

  # CALLBACKS

  ## class callbacks
  Model._callbacks = {
    'on:connect': [],
    'on:disconnect': [],
    'on:response_error': [],
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

  Model.prototype._callCallbacks = (callbackKey, args) ->
    # call class callbacks
    for callback in Model._callbacks[callbackKey]
      callback.apply(this, args)

    # call instance callbacks
    for callback in this._callbacks[callbackKey]
      callback.apply(this, args)

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