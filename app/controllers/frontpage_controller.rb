class FrontpageController < ApplicationController
  
  layout 'frontpage'
  
  def index
    @curriculums = Curriculum.all
  end
  
end
