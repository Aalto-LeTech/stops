# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  class ActionView::Helpers::FormBuilder
    
    # Usage:
    # form_for(@user) do |f|
    #   <%= f.hint :name %>
    def hint(method, options = {})
      if @object.errors.on(method)
        return '<span class="error">' + @object.errors.on(method) + '</span>'
      else
        return '<span class="hint">' + @template.t("#{@object_name}_#{method}_hint") + '</span>'
      end
    end
  end



end

