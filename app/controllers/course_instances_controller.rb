class CourseInstancesController < ApplicationController
  respond_to :json
  
  # Get all course instances
  def index
    #course_instances = CourseInstance.joins('INNER JOIN course_descriptions ON abstract_courses.abstract_course_id = course_instances.abstract_course_id').select('code, period_id')
    course_instances = CourseInstance.joins(:abstract_course).select('course_instances.id, code, period_id')
    
    respond_to do |format|
      format.html { render :text => course_instances.to_json }
      format.xml { render :xml => course_instances }
      format.json { render :json => course_instances }
    end
  end

end
