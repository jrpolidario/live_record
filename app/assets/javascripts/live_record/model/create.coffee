LiveRecord.Model.create = (config) ->
  config.modelName != undefined || throw new Error('missing :modelName argument')
  config.callbacks != undefined || config.callbacks = {}
  config.plugins != undefined || config.callbacks = {}

  # NEW
  Model = (attributes = {}) ->
    @attributes = attributes

    Object.keys(@attributes).forEach (attribute_key) ->
      if Model.prototype[attribute_key] == undefined
        Model.prototype[attribute_key] = ->
          @attributes[attribute_key]

    @_callbacks = {
      'on:connect': [],
      'on:disconnect': [],
      'on:responseError': [],
      'before:create': [],
      'after:create': [],
      'before:update': [],
      'after:update': [],
      'before:destroy': [],
      'after:destroy': []
    }

    this

  Model.modelName = config.modelName

  Model.associations =
    hasMany: config.hasMany
    belongsTo: config.belongsTo

  # getting has_many association records
  for associationName, associationConfig of Model.associations.hasMany
    Model.prototype[associationName] = ->
      self = this
      associatedModel = LiveRecord.Model.all[associationConfig.modelName]
      throw new Error('No defined model for "' + associationConfig.modelName + '"') unless associatedModel

      # TODO: speed up searching for associated records, or use cache-maps
      associatedRecords = []

      for id, record of associatedModel.all
        isAssociated = record[associationConfig.foreignKey]() == self.id()
        associatedRecords.push(record) if isAssociated

      associatedRecords

  # getting belongs_to association record
  for associationName, associationConfig of Model.associations.belongsTo
    Model.prototype[associationName] = ->
      self = this
      associatedModel = LiveRecord.Model.all[associationConfig.modelName]
      throw new Error('No defined model for "' + associationConfig.modelName + '"') unless associatedModel

      belongsToID = self[associationConfig.foreignKey]()
      associatedModel.all[belongsToID]

  Model.all = {}

  Model.subscriptions = []

  Model.autoload = (config = {}) ->
    config.callbacks ||= {}
    config.reload ||= false

    subscription = App.cable.subscriptions.create(
      {
        channel: 'LiveRecord::AutoloadsChannel'
        model_name: Model.modelName
        where: config.where
      },

      connected: ->
        # if forced reload of all records after subscribing, reload only once at the very start of connection, and no longer when reconnecting
        if config.reload
          config.reload = false
          @syncRecords()

        if @liveRecord._staleSince != undefined
          @syncRecords()

        config.callbacks['on:connect'].call(this) if config.callbacks['on:connect']

      disconnected: ->
        @liveRecord._staleSince = (new Date()).toISOString() unless @liveRecord._staleSince
        config.callbacks['on:disconnect'].call(this) if config.callbacks['on:disconnect']

      received: (data) ->
        if data.error
          @liveRecord._staleSince = (new Date()).toISOString() unless @liveRecord._staleSince
          @onError[data.error.code].call(this, data)
        else
          @onAction[data.action].call(this, data)

      onAction:
        createOrUpdate: (data) ->
          record = Model.all[data.attributes.id]

          # if record already exists
          if record
            doesRecordAlreadyExist = true
          # else if not
          else
            record = new Model(data.attributes)
            doesRecordAlreadyExist = false

          config.callbacks['before:createOrUpdate'].call(this, record) if config.callbacks['before:createOrUpdate']
          if doesRecordAlreadyExist
            record.update(data.attributes)
          else
            record.create()
          config.callbacks['after:createOrUpdate'].call(this, record) if config.callbacks['after:createOrUpdate']

      # handler for received() callback above
      onError:
        forbidden: (data) ->
          console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this)
        bad_request: (data) ->
          console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this)

      syncRecords: ->
        @perform(
          'sync_records',
          model_name: Model.modelName,
          where: config.where,
          stale_since: @liveRecord._staleSince
        )
        @liveRecord._staleSince = undefined
    )

    subscription.liveRecord = {}
    subscription.liveRecord.modelName = Model.modelName
    subscription.liveRecord.where = config.where
    subscription.liveRecord.callbacks = config.callbacks

    @subscriptions.push(subscription)
    subscription

  Model.subscribe = (config = {}) ->
    config.callbacks ||= {}
    config.reload ||= false

    subscription = App.cable.subscriptions.create(
      {
        channel: 'LiveRecord::PublicationsChannel'
        model_name: Model.modelName
        where: config.where
      },

      connected: ->
        # if forced reload of all records after subscribing, reload only once at the very start of connection, and no longer when reconnecting
        if config.reload
          config.reload = false
          @syncRecords()

        if @liveRecord._staleSince != undefined
          @syncRecords()

        config.callbacks['on:connect'].call(this) if config.callbacks['on:connect']

      disconnected: ->
        @liveRecord._staleSince = (new Date()).toISOString() unless @liveRecord._staleSince
        config.callbacks['on:disconnect'].call(this) if config.callbacks['on:disconnect']

      received: (data) ->
        if data.error
          @liveRecord._staleSince = (new Date()).toISOString() unless @liveRecord._staleSince
          @onError[data.error.code].call(this, data)
        else
          @onAction[data.action].call(this, data)

      onAction:
        create: (data) ->
          record = new Model(data.attributes)
          config.callbacks['before:create'].call(this, record) if config.callbacks['before:create']
          record.create()
          config.callbacks['after:create'].call(this, record) if config.callbacks['after:create']

      # handler for received() callback above
      onError:
        forbidden: (data) ->
          console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this)
        bad_request: (data) ->
          console.error('[LiveRecord Response Error]', data.error.code, ':', data.error.message, 'for', this)

      syncRecords: ->
        @perform(
          'sync_records',
          model_name: Model.modelName,
          where: config.where,
          stale_since: @liveRecord._staleSince
        )
        @liveRecord._staleSince = undefined
    )

    subscription.liveRecord = {}
    subscription.liveRecord.modelName = Model.modelName
    subscription.liveRecord.where = config.where
    subscription.liveRecord.callbacks = config.callbacks

    @subscriptions.push(subscription)
    subscription

  Model.unsubscribe = (subscription) ->
    index = @subscriptions.indexOf(subscription)
    throw new Error('`subscription` argument does not exist in ' + @modelName + ' subscriptions list') if index == -1

    App.cable.subscriptions.remove(subscription)

    @subscriptions.splice(index, 1)
    subscription

  Model.prototype.subscribe = (config = {}) ->
    return @subscription if @subscription != undefined

    config.reload ||= false

    # listen for record changes (update / destroy)
    subscription = App['live_record_' + @modelName() + '_' + @id()] = App.cable.subscriptions.create(
      {
        channel: 'LiveRecord::ChangesChannel'
        model_name: @modelName()
        record_id: @id()
      },

      record: ->
        return @_record if @_record
        identifier = JSON.parse(@identifier)
        @_record = Model.all[identifier.record_id]

      # on: connect
      connected: ->
        # if forced reload of this record after subscribing, reload only once at the very start of connection, and no longer when reconnecting
        if config.reload
          config.reload = false
          @syncRecord(@record())

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
          @record()._callCallbacks('on:responseError', [data.error.code])
          delete @record()['subscription']
        else
          @onAction[data.action].call(this, data)

      # handler for received() callback above
      onAction:
        update: (data) ->
          @record()._setChangesFrom(data.attributes)
          @record().update(data.attributes)
          @record()._unsetChanges()

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

    @subscription = subscription

  Model.prototype.model = ->
    Model

  Model.prototype.modelName = ->
    Model.modelName

  Model.prototype.unsubscribe = ->
    return if @subscription == undefined
    App.cable.subscriptions.remove(@subscription)
    delete this['subscription']

  Model.prototype.isSubscribed = ->
    @subscription != undefined

  # CREATE
  Model.prototype.create = (options) ->
    throw new Error(Model.modelName+'('+@id()+') is already in the store') if Model.all[@attributes.id]
    @_callCallbacks('before:create', undefined)

    Model.all[@attributes.id] = this
    # because we do not know if this newly created object is stale upon creation, then we force reload it
    @subscribe({reload: true})

    @_callCallbacks('after:create', undefined)
    this

  # UPDATE
  Model.prototype.update = (attributes) ->
    @_callCallbacks('before:update', undefined)

    self = this
    Object.keys(attributes).forEach (attribute_key) ->
      self.attributes[attribute_key] = attributes[attribute_key]

    @_callCallbacks('after:update', undefined)
    true

  # DESTROY
  Model.prototype.destroy = ->
    @_callCallbacks('before:destroy', undefined)

    @unsubscribe()
    delete Model.all[@attributes.id]

    @_callCallbacks('after:destroy', undefined)
    this

  # CALLBACKS

  Model._callbacks = {
    'on:connect': [],
    'on:disconnect': [],
    'on:responseError': [],
    'before:create': [],
    'after:create': [],
    'before:update': [],
    'after:update': [],
    'before:destroy': [],
    'after:destroy': []
  }

  # adding new callbackd to the list
  Model.prototype.addCallback = Model.addCallback = (callbackKey, callbackFunction) ->
    index = @_callbacks[callbackKey].indexOf(callbackFunction)
    if index == -1
      @_callbacks[callbackKey].push(callbackFunction)
      return callbackFunction

  # removing a callback from the list
  Model.prototype.removeCallback = Model.removeCallback = (callbackKey, callbackFunction) ->
    index = @_callbacks[callbackKey].indexOf(callbackFunction)
    if index != -1
      @_callbacks[callbackKey].splice(index, 1)
      return callbackFunction

  Model.prototype._callCallbacks = (callbackKey, args) ->
    # call class callbacks
    for callback in Model._callbacks[callbackKey]
      callback.apply(this, args)

    # call instance callbacks
    for callback in @_callbacks[callbackKey]
      callback.apply(this, args)

  Model.prototype._setChangesFrom = (attributes) ->
    @changes = {}

    for attributeName, attributeValue of attributes
      unless @attributes[attributeName] == attributeValue
        @changes[attributeName] = [@attributes[attributeName], attributeValue]

  Model.prototype._unsetChanges = () ->
    delete this['changes']

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
