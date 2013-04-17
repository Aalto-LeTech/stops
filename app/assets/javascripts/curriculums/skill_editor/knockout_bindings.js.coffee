ko.bindingHandlers.showModal =
  init: (element, valueAccessor) ->
    # Make sure the modal stays hidden once closed
    $(element).on 'hide', () ->
      valueAccessor()(false)

  update: (element, valueAccessor) ->
    value = valueAccessor()
    if ko.utils.unwrapObservable(value)
        $(element).modal('show')
    else 
        $(element).modal('hide')

ko.bindingHandlers.popover =
  init: (element, valueAccessor, allBindings, viewModel) ->
    options = valueAccessor()
    $element = $(element)
    bootstrapOptions = options.options || {}
    defaults = { container: $element }        
    options = $.extend(defaults, bootstrapOptions)
    $element.popover(options)
    # The following event listener expects the popover to be located within the
    # associated target element.
    $element.on 'click', '.popover button.close', (event) ->
      viewModel.skillErrorOccurred(false)

  update: (element, valueAccessor) ->
    options = valueAccessor()
    popoverShouldBeShown = ko.utils.unwrapObservable(options.trigger)
    if popoverShouldBeShown
      $(element).popover('show')
    else
      $(element).popover('hide')