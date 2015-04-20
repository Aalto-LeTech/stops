class FrontpageController < ApplicationController

  layout 'fixed'
  
  def index
    @user = current_user

    if not logged_in?
      @curriculums = Curriculum.where(:published => true).order('start_year DESC').all
      render :action => 'index'
    elsif @user.staff?
      @curriculums = Curriculum.order('start_year DESC').all
      render :action => 'dashboard'
      log('dashboard')
    else
      @curriculums = Curriculum.where(:published => true).order('start_year DESC').all
      render :action => 'dashboard'
      log('dashboard')
    end
  end

end
