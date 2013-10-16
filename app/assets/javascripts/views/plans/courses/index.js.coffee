#= require knockout
#= require knockout-sortable-0.7.3
#= require libs/client_event_logger

if not O4.view.i18n
  throw "The i18n strings for the view have not been loaded!"

class Plan
  constructor: (data) ->
    @courses = ko.observableArray()
    @coursesByAbstractId = {}       # abstractCourseId => Course
    
    @competences = ko.observableArray()
    @competencesById = {}           # competenceId => Competence
    
    @unattachedCourses = ko.observableArray([{course_code: '', name: '', credits: undefined, dummy: true}])
    
    this.load_json(data || {})
    
  load_json: (data) ->
    if data['plan_courses']
      coursesArray = @courses()
      for raw_plan_course in data['plan_courses']
        course = new Course()
        course.loadPlanCourse(raw_plan_course)
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

    # Put courses to competences
    for course in @courses()
      competence = @competencesById[course.competence_node_id]
      
      if competence
        competence.courses.push(course)
      else
        @unattachedCourses.push(course)
  
  

class Competence
  constructor: (@plan) ->
    @courses = ko.observableArray([{course_code: '', name: '', credits: undefined, dummy: true}])
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
  constructor: (data) ->
    data ||= {}
    
    @includedInPlan = ko.observable(false)
    @addedToPlan = ko.observable(false)
    @loading = ko.observable(false)


  loadAbstractCourse: (data) ->
    data ||= {}
    
    @dummy = false
    @abstract_course_id = data['id']
    @competence_node_id = undefined
    @grade = undefined
    @course_code = data['course_code']
    @name = data['name']
    @content = data['content']
    @period_info = data['period_info']
    @default_period = data['default_period']
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
    
    
  loadPlanCourse: (data) ->
    data ||= {}
    abstract_course_data = data['abstract_course'] || {}
    localized_description = abstract_course_data['localized_description'] || {}
    
    @dummy = false
    @abstract_course_id = data['abstract_course_id']
    @competence_node_id = data['competence_node_id']
    @grade = data['grade']
    @credits = data['credits']
    @credits_string = data['credits']
    
    @course_code = abstract_course_data['code']
    @name = abstract_course_data['localized_name']
    
    @content = ''
    @period_info = ''
    @default_period = ''
    @noppa_url = ''
    @oodi_url = ''

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
    
    @searchString = ko.observable('')
    @isLoading = ko.observable(false)
    @errorMessage = ko.observable()

  searchKeyPress: (data, event) ->
    @clickSearch() if event.which == 13
  
  clickSearch: () ->
    @isLoading(true)

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
    @resultsCallback()


class CoursesView
  constructor: () ->
    @search = new Search
      url: $('#paths').data('search-courses-path')
      callback: (data) => this.parseSearchResults(data)
      
    @searchResults = ko.observableArray()
    @selectedCourse = ko.observable()
    
    @studyplanUrl = $('#paths').data('studyplan-path')
    @plan = new Plan(window.studyplan_data)
    
    ko.applyBindings(this)
    
    @logger = new ClientEventLogger(window.client_session_id)
  
  parseSearchResults: (data) ->
    @searchResults.removeAll()
    return unless data

    # Get the underlying array so that each 'push' won't trigger dependent observables to be computed.
    searchResults = @searchResults()

    if data && data['courses']
      for result in data['courses']
        course = new Course()
        course.loadAbstractCourse(result)
        searchResults.push(course)

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
      course.includedInPlan(true)
      course.addedToPlan(true)
    
    @logger.log("ac #{course.abstract_course_id}") if @logger # add course

jQuery ->
  new CoursesView()
