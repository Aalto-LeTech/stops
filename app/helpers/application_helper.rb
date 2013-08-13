# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def nav_link_to(text, path, active_class='active')
    if current_page? path
        content_tag :li, :class => active_class do
            link_to text, path
        end
    else
        content_tag :li do
            link_to text, path
        end
    end
  end

  class ActionView::Helpers::FormBuilder

    # Usage:
    # form_for(@user) do |f|
    #   <%= f.hint :name %>
    def hint(method, options = {})
      if @object && @object.errors[method]
        html = '<span class="error">' + @object.errors[method].join('. ') + '</span>'
        return html.html_safe
      else
        html = '<span class="hint">' + @template.t("#{@object_name}_#{method}_hint") + '</span>'
        return html.html_safe
      end
    end
  end

end
