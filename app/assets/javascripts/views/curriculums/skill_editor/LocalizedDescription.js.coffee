@module 'O4', ->
  @module 'skillEditor', ->
    
    class @LocalizedDescription
      constructor: (@editor, data = {}) ->
        @id = data['id']
        @locale = data['locale']
        @name = ko.observable(data['name'] || '')
        @description = ko.observable(data['description'] || '')
        @localizedLocale = O4.skillEditor.i18n['language_in_' + @locale]

      toJson: () ->
        return false if @description().length < 1 && @name().length < 1
        
        hash = {locale: @locale}
        hash['id'] = @id if @id
        hash['description'] = @description() if @description().length > 0
        hash['name'] = @name() if @name().length > 0
        
        return hash