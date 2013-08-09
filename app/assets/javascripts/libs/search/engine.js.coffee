#= require knockout
#= require core/module_pattern

# Check that i18n strings have been loaded before this file
#if not O4.search.i18n
#  throw "search i18n strings have not been loaded!"


@module 'O4', ->
  @module 'search', ->

    class @Engine

      constructor: (opts) ->
        # @i18n = O4.search.i18n

        dbg.lg("Starting the search engine!")

        resultsContainer = $('.search-results-container')
        coursesPath = resultsContainer.data('courses-path')

        dbg.lg("db url: #{coursesPath}.")

        @model = if opts then opts.model else undefined

        # Observables
        @inquery = ko.observable()
        @results = ko.observableArray()

        @inquery.subscribe (newValue) =>
          dbg.lg("q: #{newValue}")
          return if newValue.length < 4
          $.ajax
            type: "GET",
            url: coursesPath,
            data: { 'inquery': newValue },
            context: this,
            dataType: 'json',
            success: @updateResults,
            error: @onQueryError,
            async: false

        ko.applyBindings(this)

        setInterval(
          =>
            #dbg.lg("update")
            $('#dbg').html(JSON.stringify(@results()))
          ,
          1000
        )


      updateResults: (data) ->
        dbg.lg("results: #{JSON.stringify(data)}!")
        onQueryError(data) unless data.status == 'ok'
        @results.clear
        if data.results?
          for row in data.results
            @results.push(row)
            #rawData = row.scoped_course
            #course = new GraphCourse(rawData.id, rawData.course_code, rawData.translated_name, 'course', this)


      onQueryError: (data) ->
        alert("FIXME")




# EOF
