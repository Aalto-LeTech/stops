#= require knockout-2.2.1
#= require raphael-min
#= require schedule/plan
#= require schedule/period
#= require schedule/course
#= require schedule/courseinstance

# Custom KnockOut binding for the jQuery UI draggable
# usage: data-bind="draggable: {start: dragStartHandler, stop: dragStopHandler}"
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
# usage:  data-bind="droppable: droppedObject"
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
# usage:
# @position = ko.observable({x: 0, y: 0, width: 0, height: 0})
# data-bind="position: position"
# The hash is updated with actual values when the view is first rendered.
# Position can be changed like so:
# pos = @position()
# pos.x = 10
# @position.valueHasMutated()
#
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
  $plan = $('#plan')
  planUrl = $plan.data('studyplan-path')
  #prereqsPath   = $plan.data('prereqs-path')   # '/' + locale + '/curriculums/' + curriculum_id + '/prereqs'
  #instancesPath = $plan.data('instances-path') # '/' + locale + '/course_instances'
  
  # Make schedule controls always visible (i.e., sticky)
  $scheduleControls     = $("#schedule-controls-container")
  scheduleControlsOrig  = $scheduleControls.offset().top
  
  $(window).scroll ->
    winY = $(this).scrollTop()
    if winY >= scheduleControlsOrig
      $scheduleControls.addClass("schedule-controls-fixed")
    else
      $scheduleControls.removeClass("schedule-controls-fixed")
  
  
  planView = new PlanView(planUrl)
  planView.loadPlan()
  
#   # Make text in the plan div unselectable (to make UI less annoying).
#   $("#plan").disableSelection()
# 
# 
#   # Set current period
#   currentPeriodId = $('.period[data-current-period="true"]', "#plan").data("id")
#   planView.currentPeriod  = planView.periods[currentPeriodId]
#   
#   # Attach event listeners
#   $("#save-button").click(planView.save)
# 
# 
#   # Get course prereqs by ajax
  
  
  

#   # Init Raphael
#   planView.initializeRaphael()
# 
#   # Put courses on their places
#   planView.placeCourses()
# 
#   # Place new courses automatically
#   planView.autoplan()
# 
#   # Init floating control panel
#   planView.initializeFloatingSettingsPanel()
