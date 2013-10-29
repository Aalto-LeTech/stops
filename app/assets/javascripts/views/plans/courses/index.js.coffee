#= require knockout
#= require libs/client_event_logger

# require knockout-sortable

if not O4.view.i18n
  throw "The i18n strings for the view have not been loaded!"

class Plan
  constructor: (@coursesView) ->
    @periodsById = {}   # id => Period
    
    @courses = ko.observableArray()
    @coursesByAbstractId = {}       # abstractCourseId => Course
    
    @competences = ko.observableArray()
    @competencesById = {}           # competenceId => Competence
    
  load_json: (data) ->
    if data['periods']
      for raw_period in data['periods']
        period = {
          id: raw_period['id']
          name: raw_period['localized_name']
        }
        @periodsById[period.id] = period
        
    if data['plan_courses']
      coursesArray = @courses()
      for raw_plan_course in data['plan_courses']
        course = new Course(@coursesView)
        course.loadPlanCourse(raw_plan_course, this)
        coursesArray.push(course)
        @coursesByAbstractId[course.abstract_course_id] = course
        
      @courses.valueHasMutated()
    
    if data['competences']
      competencesArray = @competences()
      for raw_competence in data['competences']
        competence = new Competence(this)
        competence.loadJson(raw_competence)
        competencesArray.push(competence)
        @competencesById[competence.competence_node_id] = competence
        
      @competences.valueHasMutated()

    this.sortCourses()
    
    # Put courses to competences
    for course in @courses()
      competence = @competencesById[course.competence_node_id]
      
      if competence
        competence.courses.push(course)
        course.competence(competence)
      
      course.competence.subscribe((-> this.competenceUpdated()), course)

  sortCourses: ->
    @courses.sort (left, right) =>
      a = left[@coursesView.courseOrder]
      b = right[@coursesView.courseOrder]
      
      if a == b
        return 0
      else if a < b
        return -1
      else
        return 1


class Competence
  constructor: (@plan) ->
    @courses = ko.observableArray()
    @prereqs = []
  
    #@courses.subscribe =>
    #  if @courses().length < 1
    #    @courses.push({course_code: '', name: '-', credits: undefined})
  
  loadJson: (data) ->
    data ||= {}
    
    @competence_node_id = data['id']
    @name = data['localized_name']
    
    if data['abstract_prereq_ids']
      for abstract_course_id in data['abstract_prereq_ids']
        course = @plan.coursesByAbstractId[abstract_course_id]
        continue unless course
        @prereqs.push(course)
        
  #{"id":102,"localized_name":"Kone- ja rakennustekniikka (sivuaine)","abstract_prereq_ids":[224,213,227,247,228,174,175]},

class Course
  constructor: (@coursesView) ->
    @addedToPlan = ko.observable(false)
    @removedFromPlan = ko.observable(false)
    @loading = ko.observable(false)
    @competence = ko.observable()

  loadAbstractCourse: (data) ->
    data ||= {}
    
    @includedInPlan = ko.observable(false)
    @plan_course_id = undefined
    @abstract_course_id = data['id']
    @competence_node_id = undefined
    @grade = undefined
    @course_code = data['course_code']
    @name = data['name']
    @content = data['content']
    @period_info = data['period_info']
    @default_period = data['default_period']
    @period_string = ''
    @noppa_url = data['noppa_url']
    @oodi_url = data['oodi_url']

    @min_credits = parseInt(data['min_credits'])
    @max_credits = parseInt(data['max_credits'])
    @credits = @min_credits
    
    if isNaN(@min_credits)
      @credits_string = ''
    else
      if isNaN(@max_credits) || @min_credits != @max_credits
        @credits_string = "#{@min_credits} - #{@max_credits}"
      else
        @credits_string = "#{@min_credits}"
    
    
  loadPlanCourse: (data, plan) ->
    data ||= {}
    abstract_course_data = data['abstract_course'] || {}
    localized_description = abstract_course_data['localized_description'] || {}
    
    @includedInPlan = ko.observable(true)
    @plan_course_id = data['id']
    @abstract_course_id = data['abstract_course_id']
    @competence_node_id = data['competence_node_id']
    @grade = data['grade']
    @credits = data['credits']
    @credits_string = data['credits']
    
    @course_code = abstract_course_data['code']
    @name = abstract_course_data['localized_name']
    @period_info = localized_description['period_info']
    @default_period = localized_description['default_period']
    @content = localized_description['content']
    @period_string = ''
    @noppa_url = localized_description['noppa_url']
    @oodi_url = localized_description['oodi_url']
    
    if data['period_id']
      period = plan.periodsById[data['period_id']]
      @period_string = period.name if period

    @min_credits = parseInt(abstract_course_data['min_credits'])
    @max_credits = parseInt(abstract_course_data['max_credits'])
    
    unless @credits_string
      if isNaN(@min_credits)
        @credits_string = ''
      else
        if isNaN(@max_credits) || @min_credits != @max_credits
          @credits_string = "#{@min_credits} - #{@max_credits}"
        else
          @credits_string = "#{@min_credits}"

  as_json: ->
    if @competence()
      competence_id = @competence().competence_node_id
    else
      competence_id = null
    
    hash = {
      'plan_course_id': @plan_course_id
      'competence_node_id': competence_id
    }
    
    console.log hash
    
    return hash

  competenceUpdated: ->
    if @competence()
      console.log @competence().name
      console.log @competence().competence_node_id

    @coursesView.saveCourse(this)
    
# "plan_courses":[
#   {
#     "abstract_course_id":220,
#     "credits":5.0,
#     "grade":0,
#     "id":512,
#     "length":null,
#     "period_id":null,
# 
#     "abstract_prereq_ids":[],
#     "abstract_course":{
#       "code":"CSE-A1111",
#       "max_credits":5,
#       "min_credits":5,
#       "localized_name": "Ohjelmoinnin peruskurssi Y1",
#       "localized_description":{"period_info":null},
#     }
#   }
# }

class Search
  constructor: (options) ->
    @searchUrl = options['url']
    @resultsCallback = options['callback']
    @startSearchCallback = options['startSearchCallback']
    @clearCallback = options['clearCallback']
    
    @searchString = ko.observable('')
    @isLoading = ko.observable(false)
    @errorMessage = ko.observable()

  searchKeyPress: (data, event) ->
    if @searchString().length < 1
      @clickClearSearch()
      
    if event.which == 13
      @clickSearch()
    
  clickSearch: () ->
    @isLoading(true)
    @startSearchCallback() if @startSearchCallback
    
    promise = $.ajax(
      url: @searchUrl
      dataType: 'json'
      data: { query: @searchString() }
    )
    
    promise.done (data) =>
      @isLoading(false)
      @errorMessage(undefined)
      @resultsCallback(data)
    
    promise.fail (data) =>
      @isLoading(false)
      @errorMessage(data['responseJSON']['message'])

  clickClearSearch: () ->
    @searchString('')
    @resultsCallback() if @resultsCallback
    @clearCallback() if @clearCallback


class CoursesView
  constructor: () ->
    @showSearchResults = ko.observable(false)
    @searchResults = ko.observableArray()
    @selectedCourse = ko.observable()
    @courseOrder = 'course_code'
    
    @search = new Search
      url: $('#paths').data('search-courses-path')
      callback: (data) => this.parseSearchResults(data)
      startSearchCallback: =>
        @showSearchResults(true)
        @selectedCourse(undefined)
      clearCallback: =>
        @showSearchResults(false)
        @selectedCourse(undefined)
      
    @studyplanUrl = $('#paths').data('studyplan-path')
    @plan = new Plan(this)
    
    ko.applyBindings(this)
    
    @plan.load_json(window.studyplan_data)
    
    @logger = new ClientEventLogger(window.client_session_id)
  
  parseSearchResults: (data) ->
    @searchResults.removeAll()
    return unless data

    # Get the underlying array so that each 'push' won't trigger dependent observables to be computed.
    searchResults = @searchResults()

    if data && data['courses']
      for result in data['courses']
        course = @plan.coursesByAbstractId[result['id']]
        unless course
          course = new Course(this)
          course.loadAbstractCourse(result)
        searchResults.push(course)
        course.competence.subscribe((-> this.competenceUpdated()), course)

    # Finally, trigger the mutation event
    @searchResults.valueHasMutated()
  
  selectCourse: (course) =>
    @selectedCourse(course)
    @logger.log("cc #{course.abstract_course_id}") if @logger # click course
    
  addCourseToPlan: (course) =>
    course.loading(true)

    promise = $.ajax(
      url: @studyplanUrl + '/courses'
      type: "POST"
      dataType: 'json'
      data: { abstract_course_id: course.abstract_course_id }
    )
    
    promise.always (data) =>
      course.loading(false)
    
    promise.done (data) =>
      course.plan_course_id = data['plan_course_id']
      course.includedInPlan(true)
      course.addedToPlan(true)
      course.removedFromPlan(false)
      
      unless @plan.coursesByAbstractId[course.abstract_course_id]
        @plan.courses.push(course)
        @plan.coursesByAbstractId[course.abstract_course_id] = course
        
      @plan.sortCourses()
      
    @logger.log("ac #{course.abstract_course_id}") if @logger # add course

  removeCourseFromPlan: (course) =>
    course.loading(true)

    promise = $.ajax(
      url: @studyplanUrl + '/courses/' + course.abstract_course_id
      type: "DELETE"
      dataType: 'json'
    )
    
    promise.always (data) =>
      course.loading(false)
    
    promise.done (data) =>
      course.includedInPlan(false)
      course.addedToPlan(false)
      course.removedFromPlan(true)
      course.competence(undefined)
      #@plan.courses.remove(course)
    
    @logger.log("rc #{course.abstract_course_id}") if @logger # add course

  saveCourse: (course) =>
    course.loading(true)

    promise = $.ajax(
      url: @studyplanUrl
      type: "PUT"
      dataType: 'json'
      data: {'plan_courses_to_update': JSON.stringify([course.as_json()])}
    )
    
    promise.always (data) =>
      course.loading(false)
    
jQuery ->
  new CoursesView()
