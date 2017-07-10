this.LiveRecord.plugins.LiveDom || (this.LiveRecord.plugins.LiveDom = {});

LiveRecord.plugins.LiveDom.applyToModel = (Model, pluginValue) ->
  return if pluginValue != true

  # DOM callbacks

  Model._updateDomCallback = ->
    $updateableElements = $('[data-cable-update-from]')

    for key, value of this.attributes
      $updateableElements.filter('[data-cable-update-from="' + Model.modelName + '-' + this.id() + '-' + key + '"]').text(this[key]())

  Model._destroyDomCallback = ->
    $('[data-cable-destroy-from="' + Model.modelName + '-' + this.id() + '"]').remove()

  Model.addCallback('after:update', Model._updateDomCallback)
  Model.addCallback('after:destroy', Model._destroyDomCallback)
