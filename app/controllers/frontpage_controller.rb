class FrontpageController < ApplicationController

  layout 'fixed'
  
  def index
    @user = current_user
    @curriculums = Curriculum.all(:order => 'start_year DESC')

    if not logged_in?
      render :action => 'index'
    elsif @user.staff?
      render :action => 'staff_dashboard'
    else
      render :action => 'student_dashboard'
      log('student_dashboard')
    end
  end

end
