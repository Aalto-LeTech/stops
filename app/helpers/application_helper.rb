# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  class ActionView::Helpers::FormBuilder
    
    # Usage:
    # form_for(@user) do |f|
    #   <%= f.hint :name %>
    def hint(method, options = {})
      if @object && @object.errors.on(method)
        html = '<span class="error">' + @object.errors.on(method) + '</span>'
        return html.html_safe
      else
        html = '<span class="hint">' + @template.t("#{@object_name}_#{method}_hint") + '</span>'
        return html.html_safe
      end
    end
  end



end

