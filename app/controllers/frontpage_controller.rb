class FrontpageController < ApplicationController

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

        if @study_plan.competences.empty?
          redirect_to studyplan_competences_path
        else
          redirect_to studyplan_schedule_path
        end
      else
        redirect_to edit_studyplan_curriculum_path
      end

    end
  end

end
