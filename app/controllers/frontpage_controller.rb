class FrontpageController < ApplicationController
  
  layout 'frontpage'
  
  def index
    @curriculums = Curriculum.all(:order => 'start_year DESC')
    
  end
  
end
