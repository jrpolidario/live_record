LiveRecord.subscribeFromNewRecords = (modelName) ->  
  modelName || throw new Error('missing modelName argument')
  Model = LiveRecord.store[modelName]

  subscription = App['live_record_' + modelName + '_create'] = App.cable.subscriptions.create({
    channel: 'LiveRecordChannel'
    model: modelName
    action: 'create'
  },
    connected: ->
    disconnected: ->
    received: (data) ->
      attributes = data[modelName]
      record = new Model(attributes)
      record.create()
  )