this.LiveRecord.plugins.iveDom || (this.LiveRecord.plugins.LiveDom = {});

LiveRecord.plugins.LiveDom.applyToModel = (Model, optionValue) ->
  return if optionValue != true

  # DOM callbacks

  Model._update_dom_callback = ->
    for key, value of this.attributes
      $('[data-cable-sync-from="' + Model.modelName + '-' + this.id() + '-' + key + '"]').text(this[key]())

  Model._create_dom_callback = ->
    self = this
    $recordsContainers = $('[data-cable-model="' + Model.modelName + '"]').parent()

    $recordsContainers.each ->
      $recordsContainer = $(this);
      $matchingRecord = $recordsContainer.find('[data-cable-model="' + Model.modelName + '"][data-cable-model-id="' + self.id() + '"]')[0]

      if $matchingRecord == undefined
        $lastRecord = $recordsContainer.find('[data-cable-model="' + Model.modelName + '"]').last()
        $clonedRecord = $lastRecord.clone()
        $cableSyncFromElements = $clonedRecord.find(':not([data-cable-model])').parent().find('[data-cable-sync-from]')

        for cableSyncFromElement in $cableSyncFromElements
          $cableSyncFromElement = $(cableSyncFromElement)
          cableSyncFromElementValues = $cableSyncFromElement.attr('data-cable-sync-from').split('-')

          cableSyncFromElementModel = cableSyncFromElementValues[0]
          cableSyncFromElementId = self.id()
          cableSyncFromElementAttribute = cableSyncFromElementValues[2]

          newCableSyncFromElementValues = [
            cableSyncFromElementModel,
            cableSyncFromElementId,
            cableSyncFromElementAttribute
          ]

          $cableSyncFromElement.attr('data-cable-sync-from', newCableSyncFromElementValues.join('-'))

        $lastRecord.after($clonedRecord);
        Model._update_dom_callback.call(self)

  Model._destroy_dom_callback = ->
    $recordsContainers = $('[data-cable-model="' + Model.modelName + '"][data-cable-model-id="' + this.id() + '"]')
    $recordsContainers.remove()

  Model.addCallback('after:create', Model._create_dom_callback)
  Model.addCallback('after:update', Model._update_dom_callback)
  Model.addCallback('after:destroy', Model._destroy_dom_callback)
