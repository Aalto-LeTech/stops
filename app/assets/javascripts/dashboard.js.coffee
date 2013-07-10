#= require knockout-2.2.1
#= require module_pattern
#= require schedule/dashboardView
#= require schedule/period
#= require schedule/course
#= require schedule/courseinstance

jQuery ->
  $plan = $('#plan')
  planUrl = $plan.data('studyplan-path')

  dashboardView = new O4.dashBoard.DashboardView(planUrl)
  dashboardView.loadPlan()
