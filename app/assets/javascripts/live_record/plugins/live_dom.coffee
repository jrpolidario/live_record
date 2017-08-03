this.LiveRecord.plugins.LiveDOM || (this.LiveRecord.plugins.LiveDOM = {});

if (window.jQuery === undefined) {
   throw new Error('jQuery is not loaded yet, and is a dependency of LiveRecord')
}

LiveRecord.plugins.LiveDOM.applyToModel = (Model, pluginValue) ->
  return if pluginValue != true

  # DOM callbacks

  Model._updateDomCallback = ->
    $updateableElements = $('[data-live-record-update-from]')

    for key, value of this.attributes
      $updateableElements.filter('[data-live-record-update-from="' + Model.modelName + '-' + this.id() + '-' + key + '"]').text(this[key]())

  Model._destroyDomCallback = ->
    $('[data-live-record-destroy-from="' + Model.modelName + '-' + this.id() + '"]').remove()

  Model.addCallback('after:update', Model._updateDomCallback)
  Model.addCallback('after:destroy', Model._destroyDomCallback)
