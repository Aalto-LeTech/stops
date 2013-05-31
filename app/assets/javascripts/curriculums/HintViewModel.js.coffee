@module 'O4', ->
  @module 'misc', ->

    class @HintViewModel
      constructor: (@hidingKey, @$hintElement) ->
        isElementShown = $hintElement.is(':visible')
        @shown = ko.observable(isElementShown)

        @shown.subscribe (shown) =>
          @setCookie() if not shown

      hideHint: ->
        @shown(false)

      setCookie: ->
        # Set a cookie that keeps the hint hidden on page loads
        document.cookie = "#{@hidingKey}=t; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT"



