#= require knockout

if not O4.view.i18n
  throw "The i18n strings for the view have not been loaded!"

class Course
  constructor: (data) ->
    data ||= {}
    
    @includedInPlan = ko.observable(false)
    @addedToPlan = ko.observable(false)
    
    @loading = ko.observable(false)
    @abstract_course_id = data['id']
    @course_code = data['course_code']
    @name = data['name']
    @content = data['content']
    @period_info = data['period_info']
    @default_period = data['default_period']
    @noppa_url = data['noppa_url']
    @oodi_url = data['oodi_url']

    @min_credits = parseInt(data['min_credits'])
    @max_credits = parseInt(data['max_credits'])
    
    if isNaN(@min_credits)
      @credits_string = ''
    else
      if isNaN(@max_credits) || @min_credits != @max_credits
        @credits_string = "#{@min_credits} - #{@max_credits}"
      else
        @credits_string = "#{@min_credits}"


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
      console.log data
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
    
    ko.applyBindings(this)
  
  parseSearchResults: (data) ->
    @searchResults.removeAll()
    return unless data

    # Get the underlying array so that each 'push' won't trigger dependent observables to be computed.
    searchResults = @searchResults()

    if data && data['courses']
      for result in data['courses']
        course = new Course(result)
        searchResults.push(course)

    # Finally, trigger the mutation event
    @searchResults.valueHasMutated()
  
  selectCourse: (course) =>
    @selectedCourse(course)
    
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

jQuery ->
  new CoursesView()
