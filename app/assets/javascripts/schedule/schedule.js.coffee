#= require knockout-2.2.1
#= require raphael-min
#= require schedule/plan
#= require schedule/period
#= require schedule/course

# require schedule/courseinstance

ko.bindingHandlers.drag = {
  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    dragElement = $(element)
    dragOptions = {
      helper: -> return dragElement.clone().addClass('ui-dragon')
      revert: true
      revertDuration: 0
      start: ->
        _hasBeenDropped = false
        _dragged = ko.utils.unwrapObservable(valueAccessor().value)

        if ($.isFunction(valueAccessor().value)) {
          valueAccessor().value(undefined)
          dragElement.draggable('option', 'revertDuration', 500)
        } else if (valueAccessor().array) {
          _draggedIndex = valueAccessor().array.indexOf(_dragged)
          valueAccessor().array.splice(_draggedIndex, 1)
        }

      stop: ->
        if (!_hasBeenDropped) {
          if ($.isFunction(valueAccessor().value)) {
            valueAccessor().value(_dragged);
          } else if (valueAccessor().array) {
            valueAccessor().array.splice(_draggedIndex, 0, _dragged);
          }
        }

      cursor: 'default'
    } # dragOptions

    dragElement.draggable(dragOptions).disableSelection()


  update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    dragElement = $(element);
    #disabled = !!ko.utils.unwrapObservable(valueAccessor().disabled)
    #dragElement.draggable('option', 'disabled', disabled)
}

ko.bindingHandlers.drop = {
  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    dropElement = $(element);
    dropOptions = {
      tolerance: 'pointer',
      drop: (event, ui) ->
        _hasBeenDropped = true
        valueAccessor().value(_dragged)
        ui.draggable.draggable('option', 'revertDuration', 0)
    }

    dropElement.droppable(dropOptions);


  update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    dropElement = $(element);
    #disabled = !!ko.utils.unwrapObservable(valueAccessor().disabled);
    #dropElement.droppable('option', 'disabled', disabled); didn't work. jQueryUI bug?
    #dropElement.droppable('option', 'accept', disabled ? '.nothing' : '*');
}

# ko.bindingHandlers.jqDraggable = {
#   init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
#     obj = valueAccessor()
#     $elem = $(element)
#     element.dataObj = obj
# 
#     $elem.draggable
#       stop: (event, ui) ->
#         this.dataObj.x(ui.position.left)
#         this.dataObj.x(ui.position.top)
# }
                
jQuery ->
  planView = new PlanView()
  
  # Make schedule controls always visible (i.e., sticky)
  $scheduleControls     = $("#schedule-controls-container")
  scheduleControlsOrig  = $scheduleControls.offset().top
  
  $(window).scroll ->
    winY = $(this).scrollTop()
    if winY >= scheduleControlsOrig
      $scheduleControls.addClass("schedule-controls-fixed")
    else
      $scheduleControls.removeClass("schedule-controls-fixed")


#   # Create a Course object for each course element
#   $('.course').each (i, element) ->
#     new Course($(element))
# 
# 
#   # Make text in the plan div unselectable (to make UI less annoying).
#   $("#plan").disableSelection()
# 
#   # Create a Period object for each period element
#   periodCounter = 0
#   $('.period').each (i, element) ->
#     period = new Period($(element));
#     planView.addPeriod(period);
# 
#     planView.firstPeriod = period unless previousPeriod
# 
#     period.setSequenceNumber(periodCounter)
#     period.setPreviousPeriod(previousPeriod)
# 
#     previousPeriod = period
#     periodCounter++
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
  $plan = $('#plan')
  prereqsPath   = $plan.data('prereqs-path')   # '/' + locale + '/curriculums/' + curriculum_id + '/prereqs'
  instancesPath = $plan.data('instances-path') # '/' + locale + '/course_instances'
  planUrl = $plan.data('studyplan-path')
# 
  
  $.ajax
    url: planUrl,
    dataType: 'json',
    success: $.proxy(planView.loadPlan, planView)

#   $.ajax
#     url: prereqsPath,
#     dataType: 'json',
#     success: planView.loadPrereqs,
#     async: false
# 
#   $.ajax
#     url: instancesPath,
#     dataType: 'json',
#     success: planView.loadCourseInstances,
#     async: false
# 
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
