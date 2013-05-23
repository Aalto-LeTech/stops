#= require knockout-2.2.1
#= require plans/knockout_bindings

addToStudyPlanURL      = '/fi/studyplan/competences/add_competence_to_plan'
removeFromStudyPlanURL = '/fi/studyplan/competences/remove_competence_from_plan'

# View Model
class Competence
  constructor: (@id, includedInPlan) ->
    @includedInPlan = ko.observable(includedInPlan)
    @loading        = ko.observable(false)
    @i18n           = O4.competenceElection.i18n

  # Execution context must be bound to the context of this view model, because
  # this callback will be executed in a knockout binding.
  clickAddOrRemoveButton: () =>
    console.log "Button clicked (Competence id: #{@id})"

    @loading(true)

    if @includedInPlan()
      promise = $.ajax
        url: removeFromStudyPlanURL
        data:
          id: @id

    else
      promise = $.ajax
        url: addToStudyPlanURL
        data:
          id: @id

    promise.done () =>
      @loading(false)
      @includedInPlan(!@includedInPlan())

    promise.fail () =>
      @loading(false)

# View Model
class CompetenceElectionEditor
  constructor: ->
    @competencesById = {}


    # Initialize Competence objects
    $('#competence-list > [data-competence-id]').each (i, el) =>
      id             = $(el).data('competence-id')
      includedInPlan = $(el).data('competence-included')
      @competencesById[id] = new Competence id, includedInPlan
    
    ko.applyBindings(this)



jQuery ->
  new CompetenceElectionEditor