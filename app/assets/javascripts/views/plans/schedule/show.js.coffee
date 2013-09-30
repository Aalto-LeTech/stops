#= require knockout
#= require core/knockout-extensions
#= require core/knockout-dragdrop
#= require ./plan
#= require ./period
#= require ./course
#= require ./courseinstance
#= require ./competence
#= require ./scheduler

jQuery ->
  $plan = $('#plan-container')
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
    .on 'mousedown', '#controls, .object-info, #plan-container', (event) ->
      event.stopPropagation()
    .on 'mousedown', 'div.leftnav-content', (event) ->
      planView.unselectObjects()
    .on 'keypress', 'body', (event) ->
      obj = planView.selectedObject()
      if obj and obj.keyPress and obj.keyPress(planView, event.keyCode)
        event.preventDefault()

  $(window).bind 'beforeunload', =>
    return "You have unsaved changes on #{planView.coursesToSave.length} course(s). Leave anyway?" if planView.anyUnsavedChanges()

  #planView.loadPlan()
  planView.loadJson(schedule_data)
