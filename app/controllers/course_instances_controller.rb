class CourseInstancesController < ApplicationController
  respond_to :json
  
  # Get all course instances. FIXME: this seems to be obsolete
  def index
    course_instances = CourseInstance.joins(:abstract_course).select('course_instances.id, code, period_id, length')
    
    respond_to do |format|
      format.html { render :text => course_instances.to_json }
      format.xml { render :xml => course_instances }
      format.json { render :json => course_instances.to_json(:root => false) }
    end
  end

end
