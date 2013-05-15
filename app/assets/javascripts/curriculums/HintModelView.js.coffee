@module 'O4', ->
  @module 'misc', ->

    class @HintModelView
      constructor: (@hidingKey, @url, @$hintElement) ->
        isElementShown = $hintElement.is(':visible')
        @shown = ko.observable(isElementShown)

        @shown.subscribe (shown) =>
          @setCookie() if not shown

      hideHint: ->
        @shown(false)

      setCookie: ->
        # Set a cookie that keeps the hint hidden on page loads
        dataObj = {}
        dataObj[@hidingKey] = ''

        $.ajax
          url: @url
          type: 'GET'
          data: dataObj



