LiveRecord.plugins.LiveDOM.applyToModel = (Model, pluginValue) ->
  return if pluginValue != true

  # DOM callbacks
  Model._updateDomCallback = (domContext)->
    domContext ||= $('body')

    $updatableElements = domContext.find('[data-live-record-update-from]')

    for key, value of this.attributes
      $updatableElements.filter('[data-live-record-update-from="' + Model.modelName + '-' + this.id() + '-' + key + '"]').text(this[key]())

  Model._destroyDomCallback = ->
    $('[data-live-record-destroy-from="' + Model.modelName + '-' + this.id() + '"]').remove()
  
  Model.addCallback('after:update', Model._updateDomCallback)
  Model.addCallback('after:destroy', Model._destroyDomCallback)
