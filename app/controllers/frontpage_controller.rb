class FrontpageController < ApplicationController

  layout 'fixed'
  
  def index
    @user = current_user

    if not logged_in?
      render :action => 'index'
    elsif @user.staff?
      @curriculums = Curriculum.all(:order => 'start_year DESC')
      render :action => 'dashboard'
      log('dashboard')
    else
      # TODO: hide unpublished curricula from students
      @curriculums = Curriculum.where(:published => true).order('start_year DESC').all
      render :action => 'dashboard'
      log('dashboard')
    end
  end

end
