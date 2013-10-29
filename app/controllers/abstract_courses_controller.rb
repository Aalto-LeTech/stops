class AbstractCoursesController < ApplicationController
  respond_to :json
  
  def search
    queryID    = params[:queryID]
    do_star      = params[:star] || true
    max_matches  = params[:max_matches] || 100
    
    # Form the query
    # Replace whitespace with stars ('diff eq' -> '*diff* *eq*')
    query = '*' + Riddle::Query.escape(params[:query].strip()).gsub(/\s+/, '* *') + '*'
    
    begin
      unless query
        response_data = { status: 'error', queryID: queryID }
      else query
        log("search_course #{params[:query]}")

        abstract_courses = AbstractCourse.search(
          query,
          ranker:      :proximity_bm25,
          max_matches: max_matches,
          per_page:    max_matches,
          sql:         { :include => [:localized_description] }
        )

        abstract_courses_json = abstract_courses.map do |abstract_course|
          hash = {
            'id' => abstract_course.id,
            'course_code'=> abstract_course.code,
            'min_credits' => abstract_course.min_credits,
            'max_credits' => abstract_course.max_credits,
          }
          
          localized_description = abstract_course.localized_description
          if localized_description
            hash['name'] = localized_description.name
            hash['content'] = localized_description.content
            hash['noppa_url'] = localized_description.noppa_url
            hash['oodi_url'] = localized_description.oodi_url
            hash['default_period'] = localized_description.default_period
            hash['period_info'] = localized_description.period_info
          end
          
          hash
        end
        
        response_data = {
          status: 'ok',
          queryID:  queryID,
          courses: abstract_courses_json
        }
      end

      respond_to do |format|
        format.js do
          render :json => response_data.to_json(:root => false)
        end
      end
#     rescue Exception => e
#       respond_to do |format|
#         format.js do
#           render :json => { status: 'error', message: 'Search server is temporarily offline' }.to_json(:root => false), :status => 500
#         end
#       end
#       
#       ErrorMailer.warning_message('Sphinx is not running', 'Thinking Sphinx is not running').deliver
    end
  end
end
