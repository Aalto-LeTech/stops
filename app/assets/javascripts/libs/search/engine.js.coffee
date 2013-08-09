#= require knockout
#= require core/module_pattern

# Check that i18n strings have been loaded before this file
if not O4.search.i18n
  throw "search i18n strings have not been loaded!"


@module 'O4', ->
  @module 'search', ->

    class @Engine

      constructor: (opts) ->
        @i18n = O4.search.i18n

        dbg.lg("Starting the search engine!")

        resultsContainer = $('.search-results-container')
        serverPath = resultsContainer.data('courses-path')

        dbg.lg("db url: #{serverPath}.")

        @model = if opts then opts.model else undefined

        # Observables
        @infomsg = ko.observable(@i18n.query_too_short)
        @inquery = ko.observable()
        @results = ko.observableArray()

        @inquery.subscribe (newValue) =>
          dbg.lg("q: #{newValue}")

          if newValue.length < 3
            @infomsg(@i18n.query_too_short)
            if newValue.length > 0
              @results([])
            return

          $.ajax
            type: "GET",
            url: serverPath,
            data: { 'inquery': newValue },
            context: this,
            dataType: 'json',
            success: @updateResults,
            error: @onQueryError,
            async: true

        ko.applyBindings(this)

        # Event handlers
        $(document)
          .on 'mousedown', '.result', (event) ->
            object = ko.dataFor(this)
            dbg.lg(object.path)
            $('#dbg').text(object.path)
            event.stopPropagation()

#        setInterval(
#          =>
#            #dbg.lg("update")
#            $('#dbg').html(JSON.stringify(@results()))
#          ,
#          1000
#        )


      updateResults: (data) ->
        #dbg.lg("results: #{JSON.stringify(data)}!")
        onQueryError(data) unless data.status == 'ok'
        return if data.inquery != @inquery()
        @results([])
        if data.scoped_courses?
          for scoped_course in data.scoped_courses
            if scoped_course.link?
              scoped_course.link = "<a href=\"#{scoped_course.link}\"></a>"
            @results.push(scoped_course)
        nresults = @results().length
        if nresults == 0
          @infomsg(@i18n.no_results_found)
        else if nresults == 1
          @infomsg(@i18n.a_result_found)
        else
          @infomsg(nresults + ' ' + @i18n.x_results_found)


      onQueryError: (data) ->
        dbg.lg("FIXME!")
        #dbg.lg("FIXME: #{JSON.stringify(data)}!")




# EOF
