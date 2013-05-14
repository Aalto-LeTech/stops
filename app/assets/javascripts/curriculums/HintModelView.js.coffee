@module 'O4', ->
  @module 'misc', ->

    class @HintModelView
      constructor: (@hidingKey, @url) ->
        @hidden = ko.observable(false)

      hideMessage: ->
        @hidden(true)

        # Set a cookie through AJAX request
        dataObj = {}
        dataObj[@hidingKey] = ''

        $.ajax
          url: @url
          type: 'GET'
          data: dataObj



