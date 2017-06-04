this.LiveRecord.plugins.liveDom || (this.LiveRecord.plugins.liveDom = {});

LiveRecord.plugins.liveDom.applyToModel = (model, modelName, optionValue) ->
  return if optionValue != true

  # DOM callbacks

  model._update_dom_callback = ->
    for key, value of this.attributes
      $('[data-cable-sync-from="' + modelName + '-' + this.id() + '-' + key + '"]').text(this[key]())

  model._create_dom_callback = ->
    self = this
    $recordsContainers = $('[data-cable-model="' + modelName + '"]').parent()

    $recordsContainers.each ->
      $recordsContainer = $(this);
      $matchingRecord = $recordsContainer.find('[data-cable-model="' + modelName + '"][data-cable-model-id="' + self.id() + '"]')[0]

      if $matchingRecord == undefined
        $lastRecord = $recordsContainer.find('[data-cable-model="' + modelName + '"]').last()
        $clonedRecord = $lastRecord.clone()
        $cableSyncFromElements = $clonedRecord.find(':not([data-cable-model])').parent().find('[data-cable-sync-from]')

        for cableSyncFromElement in $cableSyncFromElements
          $cableSyncFromElement = $(cableSyncFromElement)
          cableSyncFromElementValues = $cableSyncFromElement.attr('data-cable-sync-from').split('-')

          cableSyncFromElementmodel = cableSyncFromElementValues[0]
          cableSyncFromElementId = self.id()
          cableSyncFromElementAttribute = cableSyncFromElementValues[2]

          newCableSyncFromElementValues = [
            cableSyncFromElementmodel,
            cableSyncFromElementId,
            cableSyncFromElementAttribute
          ]

          $cableSyncFromElement.attr('data-cable-sync-from', newCableSyncFromElementValues.join('-'))

        $lastRecord.after($clonedRecord);
        model._update_dom_callback.call(self)

  model._destroy_dom_callback = ->
    $recordsContainers = $('[data-cable-model="' + modelName + '"][data-cable-model-id="' + this.id() + '"]')
    $recordsContainers.remove()

  model.addCallback('after:create', model._create_dom_callback)
  model.addCallback('after:update', model._update_dom_callback)
  model.addCallback('after:destroy', model._destroy_dom_callback)
