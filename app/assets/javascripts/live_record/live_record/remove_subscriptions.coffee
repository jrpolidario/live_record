LiveRecord.removeSubscriptions = (subscriptions) ->
  for subscription in subscriptions
    App.cable.subscriptions.remove(subscription)