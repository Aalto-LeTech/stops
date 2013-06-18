class FrontpageController < ApplicationController
  
  layout 'frontpage'
  
  def index
    @curriculums = Curriculum.all(:order => 'start_year DESC')
    unless logged_in?
      render :action => 'index'
    else
      render :action => 'dashboard'
    end
  end
  
end
