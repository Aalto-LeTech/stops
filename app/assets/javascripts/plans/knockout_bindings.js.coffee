unwrap = ko.utils.unwrapObservable

ko.bindingHandlers.statefulButton =
  init: (element, valueAccessor, allBindings, viewModel) ->
    options = valueAccessor()

    loading       = unwrap(options.loading)
    clickCallback = unwrap(options.click)    || () ->

    $(element).click ->
      if not loading
        clickCallback()

  update: (element, valueAccessor) ->
    options = valueAccessor()

    loading              = unwrap(options.loading)
    loadingClass         = unwrap(options.loadingClass)         || 'disabled'
    primaryStateOn       = unwrap(options.primaryState)
    primaryStateClass    = unwrap(options.primaryClass)         || 'btn-success'
    secondaryStateClass  = unwrap(options.secondaryClass)       || 'btn-danger'
    primaryText          = unwrap(options.primaryText)          || 'Primary text'
    secondaryText        = unwrap(options.secondaryText)        || 'Secondary text'
    primaryLoadingText   = unwrap(options.primaryLoadingText)   || 'Primary loading text'
    secondaryLoadingText = unwrap(options.secondaryLoadingText) || 'Secondary loading text'

    $el = $(element)

    # Check which styles need be applied
    if primaryStateOn
      $el.addClass(primaryStateClass).removeClass(secondaryStateClass)

      if loading
        # Change to loading styling
        $el.addClass(loadingClass).attr('disabled', 'disabled')
        $el.html(primaryLoadingText)
      else
        # Remove loading styling
        $el.removeClass(loadingClass).removeAttr('disabled')
        $el.html(primaryText)

    else
      $el.addClass(secondaryStateClass).removeClass(primaryStateClass)

      if loading
        # Change to loading styling
        $el.addClass(loadingClass).attr('disabled', 'disabled')
        $el.html(secondaryLoadingText)
      else
        # Remove loading styling
        $el.removeClass(loadingClass).removeAttr('disabled')
        $el.html(secondaryText)

       