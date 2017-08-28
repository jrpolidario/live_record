LiveRecord.plugins.LiveDOM.LiveList.create = (config) ->
	live_list = new LiveRecord.plugins.LiveDOM.LiveList(config)
	live_list_store = LiveRecord.plugins.LiveDOM.LiveList.all

	live_list_store[config.modelName] ||= []
	live_list_store[config.modelName].push(live_list)
	live_list