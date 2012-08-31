module O4::BreadcrumbExtensions

  # A Builder for BreadcrumbsOnRails that renders breadcrumbs compatible with Bootstrap
  class BootstrapBreadcrumbsBuilder < BreadcrumbsOnRails::Breadcrumbs::Builder
    def render
        crumbs = @elements.map do |element|
          render_element(element)
        end.join("\n")

        @context.content_tag("div", crumbs, {:class => "breadcrumb"}, false)
    end

    def render_element(element)
      path = compute_path(element)
      if @context.current_page? path
        @context.content_tag :li, compute_name(element), :class => 'active'
      else
        link    = @context.link_to(compute_name(element), path, element.options)
        divider = @context.content_tag(:span, @options[:separator] || '/', {:class => 'divider'}, false)
        @context.content_tag(:li, link + divider)
      end
    end
  end
end