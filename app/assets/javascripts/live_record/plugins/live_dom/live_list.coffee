#= require_self
#= require_directory ./live_list/

LiveRecord.plugins.LiveDOM.LiveList = (config) ->
  throw new Error('missing :modelName argument') unless config.modelName
  throw new Error(':modelName does not match any created Models') unless LiveRecord.Model.all[config.modelName]

  @config = config

  # by default, sorts by ID ascending 
  @config.sort ||= (record1, record2) ->
      LiveRecord.helpers.spaceship(record1.id(), record2.id())
  this

LiveRecord.plugins.LiveDOM.LiveList.prototype.createElement = (record) ->
  throw new Error('`record` modelName does not match this LiveList modelName') if @config.modelName != record.modelName()

  self = this

  $listContainer = @config.listContainer
  # evaluate function first if a function
  $listContainer = $listContainer() if typeof $listContainer == 'function'

  # dont recreate if element already exists in LiveList
  return if $listContainer.find('> [data-live-record-element="' + record.modelName() + '-' + record.id() + '"]').length > 0

  $clonedElement = $listContainer.find('> [data-live-record-element]').first().clone()

  tempArray = $clonedElement.attr('data-live-record-element').split('-')
  modelName = tempArray[0]
  recordId = parseInt(tempArray[1])


  $updatableElements = $clonedElement.find('[data-live-record-update-from]')
  $destroyableElements = $clonedElement.find('[data-live-record-destroy-from]')

  $updatableElements.each(
    ->
      $updatableElement = $(this)

      # update the ID to match the newly created record
      tempArray = $updatableElement.attr('data-live-record-update-from').split('-')
      modelName = tempArray[0]
      recordAttribute = tempArray[2]

      newValue = modelName + '-' + record.id() + '-' + recordAttribute
      $updatableElement.attr('data-live-record-update-from', newValue)

      # next, update also all text content within cloned-element-DOM
      record.model()._updateDomCallback.call(record, $clonedElement)
  )

  $destroyableElements.each(
    ->
      $destroyableElement = $(this)

      # update the ID to match the newly created record
      tempArray = $destroyableElement.attr('data-live-record-destroy-from').split('-')
      modelName = tempArray[0]

      newValue = modelName + '-' + record.id()
      $destroyableElement.attr('data-live-record-destroy-from', newValue)
  )

  # TODO: figure out next where to insert this clonedElement into the LiveList
  $listContainer.append($clonedElement)

  this.syncElements()

LiveRecord.plugins.LiveDOM.LiveList.prototype.syncElements = ->
  self = this

  $listContainer = @config.listContainer
  # evaluate function first if a function
  $listContainer = $listContainer() if typeof $listContainer == 'function'

  $elements = $listContainer.find('> [data-live-record-element]')

  # check for elements that are not yet in the _elements-store
  $elements.each(
    ->
      $element = $(this)

      tempArray = $element.attr('data-live-record-element').split('-')
      modelName = tempArray[0]
      recordId = parseInt(tempArray[1])

      unless $element.data('__live_record_live_list')
        $element.data('__live_record_live_list', self)
        $element.data('__live_record_record', LiveRecord.Model.all[modelName][recordId])
        self.elements.push($element)
  )

  @sortElements()
  @elements

LiveRecord.plugins.LiveDOM.LiveList.prototype.sortElements = ->
  @elements.sort(
    ($element1, $element2) ->
  )
  #     LiveRecord.helpers.spaceship
  # for $element in @elements
  #   $element.data('__live_record_record')

LiveRecord.plugins.LiveDOM.LiveList.prototype.elements = []
