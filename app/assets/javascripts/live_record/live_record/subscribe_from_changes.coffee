LiveRecord.subscribeFromChanges = (modelName, id) ->
  modelName || throw new Error('missing modelName argument')
  modelName || throw new Error('missing id argument')
  Model = LiveRecord.store[modelName]

  # listen for record "update"
  subscription1 = App['live_record_' + modelName + '_update_' + id] = App.cable.subscriptions.create({
    channel: 'LiveRecordChannel'
    model: modelName
    action: 'update'
    id: id
  },
    connected: ->
    disconnected: ->
    received: (data) ->
      identifier = JSON.parse(this.identifier)
      attributes = data[modelName]
      record = Model.all[identifier.id]
      record.update(attributes)
  )

  # listen for record "destroy"
  subscription2 = App['live_record_' + modelName + '_destroy_' + id] = App.cable.subscriptions.create({
    channel: 'LiveRecordChannel'
    model: modelName
    action: 'destroy'
    id: id
  },
    connected: ->
    disconnected: ->
    received: (data) ->
      identifier = JSON.parse(this.identifier)
      record = Model.all[identifier.id]
      record.destroy()
  )

  [subscription1, subscription2]