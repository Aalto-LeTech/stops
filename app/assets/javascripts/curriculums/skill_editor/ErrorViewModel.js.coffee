@module 'O4', ->
  @module 'skillEditor', ->
    
    class @ErrorViewModel
      constructor: ->
        @shown   = ko.observable(false)
        @heading = ko.observable('')
        @message = ko.observable('')

      showErrorMessage: (heading, message) ->
        @heading heading
        @message message
        @shown true

      clickClose: ->
        @shown false