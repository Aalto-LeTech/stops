#= require knockout-2.2.1
#= require schedule/dashboardView
#= require schedule/period
#= require schedule/course
#= require schedule/courseinstance

jQuery ->
  $plan = $('#plan')
  planUrl = $plan.data('studyplan-path')

  dashboardView = new DashboardView(planUrl)
  dashboardView.loadPlan()
