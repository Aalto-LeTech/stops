#= require core/module_pattern
#= require core/strings


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
        @infoMsg     = ko.observable(@i18n.query_too_short)
        @inquery     = ko.observable()
        @inqueryS    = undefined
        @inqueryID   = undefined
        @doStar      = ko.observable(true)
        @maxMatches  = ko.observable(20)
        @results     = ko.observableArray()
        @viewModel   = viewModel


        @inquery.subscribe (newValue) =>
          #dbg.lg("q: #{newValue}")

          @viewModel.onInqueryChange()

          newValue = newValue.trim()

          if newValue.length < @MIN_QUERY_LENGTH
            @infoMsg(@i18n.query_too_short)
            if newValue.length > 0
              @results().length = 0
              @results.valueHasMutated()
            return

          newinqueryS = newValue
          #newinqueryS = '"' + newValue + '"'
          #newinqueryS = '*' + newValue + '*'

          return if newinqueryS == @inqueryS

          @inqueryS = newinqueryS
          @inqueryID = String(new Date().getTime())

          $.ajax
            type: "GET",
            url: serverPath,
            data: {
              'inqueryID':   @inqueryID,
              'inquery':     @inqueryS,
              'star':        @doStar(),
              'max_matches': @maxMatches()
            },
            context: this,
            dataType: 'json',
            success: @updateResults,
            error: @onQueryError,
            async: true


      updateResults: (data) ->
        #dbg.lg("results: #{JSON.stringify(data)}!")
        #dbg.lg("dataIDs: #{data.inqueryID} vs #{@inqueryID}.")
        onQueryError(data) unless data.status == 'ok'
        return if data.inqueryID != @inqueryID

        # Have the viewModel handle building the final results array
        @results( @viewModel.parseResults(data) )

        # Update the info message
        nresults = @results().length
        if nresults == 0
          @infoMsg(@i18n.no_results_found)
        else if nresults == 1
          @infoMsg(@i18n.a_result_found)
        else
          @infoMsg(nresults + ' ' + @i18n.x_results_found)


      onQueryError: (data) ->
        dbg.lg("FIXME!")
        #dbg.lg("FIXME: #{JSON.stringify(data)}!")




# EOF
