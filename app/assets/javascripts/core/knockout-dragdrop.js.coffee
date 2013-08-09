# knockout-dragdrop.js.coffee v1.0
#
# Knockout binding handlers implemented to offer a drag and drop behaviour
#




# Custom KnockOut binding for the jQuery UI draggable
ko.bindingHandlers.draggable = {
  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    startCallback = valueAccessor().start
    stopCallback = valueAccessor().stop

    dragOptions = {
      containment: 'parent'
      distance: 5
      cursor: 'default'
    }

    dragOptions['start'] = (-> startCallback.call(viewModel)) if startCallback
    dragOptions['stop'] = (-> stopCallback.call(viewModel)) if stopCallback

    $(element).draggable(dragOptions).disableSelection()
}


# Custom KnockOut binding for the jQuery UI droppable
ko.bindingHandlers.droppable = {
  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    dropOptions = {
      tolerance: 'pointer',
      drop: (event, ui) ->
        dragObject = ko.dataFor(ui.draggable.get(0))
        valueAccessor()(dragObject)
    }

    $(element).droppable(dropOptions)
}


# Custom KnockOut binding that makes it possible to move DOM objects.
ko.bindingHandlers.position = {
  init: (element, valueAccessor, bindingHandlers, viewModel) ->
    #dbg.lg("ko::position.init()")
    pos = $(element).position()
    value = ko.utils.unwrapObservable(valueAccessor())
    value.x = pos.left if value.x?
    value.y = pos.top if value.y?
    #dbg.lg(" - position: #{value.x} #{value.y}")
    value.width = pos.width if value.width?
    value.height = pos.height if value.height?

  update: (element, valueAccessor, bindingHandlers, viewModel) ->
    #dbg.lg("ko::position.update()")
    value = ko.utils.unwrapObservable(valueAccessor())
    el = $(element)

    options = {}
    options['left'] = value.x if value.x?
    options['top'] = value.y if value.y?
    options['width'] = value.width if value.width?
    options['height'] = value.height if value.height?
    #dbg.lg(" - position: #{value.x} #{value.y}")

    el.animate(options, 150)
}
