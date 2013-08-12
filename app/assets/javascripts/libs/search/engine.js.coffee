#= require core/module_pattern
#= require ./course

# Check that i18n strings have been loaded before this file
if not O4.search.i18n
  throw "search i18n strings have not been loaded!"


@module 'O4', ->
  @module 'search', ->

    class @Engine

      MIN_QUERY_LENGTH: 3

      constructor: (viewModel, serverPath, opts) ->
        @i18n = O4.search.i18n

        # Observables
        @infomsg = ko.observable(@i18n.query_too_short)
        @inquery = ko.observable()
        @results = ko.observableArray()
        @viewModel = viewModel


        @inquery.subscribe (newValue) =>
          #dbg.lg("q: #{newValue}")

          @viewModel.onInqueryChange()

          if newValue.length < @MIN_QUERY_LENGTH
            @infomsg(@i18n.query_too_short)
            if newValue.length > 0
              @results().length = 0
              @results.valueHasMutated()
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


        @results.subscribe (newValue) =>
          @viewModel.onResultsChange()


      updateResults: (data) ->
        #dbg.lg("results: #{JSON.stringify(data)}!")
        onQueryError(data) unless data.status == 'ok'
        return if data.inquery != @inquery()
        @results().length = 0

        # Build objects from all the result data served and include them as
        # results
        Course::resetFromJson(data)
        @results().push.apply(@results(), Course::ALL)

        # Update the info message
        nresults = @results().length
        if nresults == 0
          @infomsg(@i18n.no_results_found)
        else if nresults == 1
          @infomsg(@i18n.a_result_found)
        else
          @infomsg(nresults + ' ' + @i18n.x_results_found)

        # Update the DOM
        @results.valueHasMutated()


      onQueryError: (data) ->
        dbg.lg("FIXME!")
        #dbg.lg("FIXME: #{JSON.stringify(data)}!")




# EOF
