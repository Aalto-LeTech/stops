class FrontpageController < ApplicationController
  
  include CompetencesHelper

  layout 'frontpage'
  
  def index
    @user = current_user
    @curriculums = Curriculum.all(:order => 'start_year DESC')
    unless logged_in?
      render :action => 'index'
    else
      @chosen_competences = get_chosen_competences
#      @vi_courses = @user.study_plan.courses.where( :period_id =>  )
      @vi_courses = @user.study_plan.study_plan_courses.joins(:course_instance).where( :course_instances => { :period_id => 2 } ).limit(8)

      render :action => 'dashboard'
    end
  end
  
end
