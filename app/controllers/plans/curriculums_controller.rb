class Plans::CurriculumsController < PlansController
  
  before_filter :authenticate_user!
  before_filter :load_plan
  before_filter :load_plan
  before_filter :load_curriculum, :only => :show
  
  def show
    
  end
  

  def edit
    @curriculums = Curriculum.order(:start_year)
  end

  
  def update
    
    @user.curriculum_id = params[:user][:curriculum]
    @user.save

    redirect_to studyplan_path
#     respond_to do |format|
#       if @course.update_attributes(params[:course])
#         format.html { redirect_to(@course, :notice => 'Course was successfully updated.') }
#         format.xml  { head :ok }
#       else
#         format.html { render :action => "edit" }
#         format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
#       end
#     end
  end

end
