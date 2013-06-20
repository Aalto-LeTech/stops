class FrontpageController < ApplicationController

  layout 'frontpage'
  
  def index
    @user = current_user
    @curriculums = Curriculum.all(:order => 'start_year DESC')
    
    if not logged_in?
      render :action => 'index'
    elsif @user.staff?
      render :action => 'staff_dashboard'
    else

      @study_plan = @user.study_plan
      
      if @study_plan
        @chosen_competence_ids = @study_plan.competence_ids.to_set

        @current_period = Period.first
        @current_courses = @study_plan.study_plan_courses.where( :period_id => @current_period.id ).limit(8)
        render :action => 'student_dashboard'
      else
        redirect_to edit_studyplan_curriculum_path
      end

    end
  end
  
end
