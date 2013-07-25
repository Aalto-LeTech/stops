#= require knockout-2.3.0
#= require knockoutxtra
#= require schedule/plan
#= require schedule/period
#= require schedule/course
#= require schedule/courseinstance
#= require schedule/competence
#= require schedule/scheduler


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
    pos = $(element).position()
    value = ko.utils.unwrapObservable(valueAccessor())
    value.x = pos.left if value.x?
    value.y = pos.top if value.y?
    value.width = pos.width if value.width?
    value.height = pos.height if value.height?

  update: (element, valueAccessor, bindingHandlers, viewModel) ->
    value = ko.utils.unwrapObservable(valueAccessor())
    el = $(element)

    options = {}
    options['left'] = value.x if value.x?
    options['top'] = value.y if value.y?
    options['width'] = value.width if value.width?
    options['height'] = value.height if value.height?

    el.animate(options, 150)
}


jQuery ->
  dbg("jQuery Start!")

  $plan = $('#plan')
  planUrl = $plan.data('studyplan-path')

  # Make text in the plan div unselectable (to make UI less annoying).
  $plan.disableSelection()

  planView = new PlanView(planUrl)

  # Event handlers
  $(document)
    .on 'mousedown', '.course, .period, .competencex', (event) ->
      object = ko.dataFor(this)
      planView.selectObject(object) if event.which == 1
      event.stopPropagation()
    .on 'mousedown', '.well', (event) ->
      event.stopPropagation()
    .on 'mousedown', 'body', (event) ->
      planView.unselectObjects()
    .on 'mouseenter', '#sidebar .well', (event) ->
      #dbg("Mouse In: Well!")
      planView.doShowAsEditable()
    .on 'mouseleave', '#sidebar .well', (event) ->
      #dbg("Mouse Out: Well!")
      planView.noShowAsEditable()

  planView.loadPlan()
