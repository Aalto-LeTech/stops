class ProfilesController < ApplicationController
  
  layout 'profile'
  

  # GET /profiles/1
  # GET /profiles/1.xml
#   def show
#     @profile = Profile.find(params[:id])
#     
#     #@courses = @profile.ordered_courses
#     @semesters = @profile.semesters
#     
#     respond_to do |format|
#       format.html # show.html.erb
#       format.xml  { render :xml => @course }
#     end
#   end


  # GET /courses/1/edit
#   def edit
#     @course = Course.find(params[:id])
#   end

  # POST /courses
  # POST /courses.xml
#   def create
#     @course = Course.new(params[:course])
# 
#     respond_to do |format|
#       if @course.save
#         format.html { redirect_to(@course, :notice => 'Course was successfully created.') }
#         format.xml  { render :xml => @course, :status => :created, :location => @course }
#       else
#         format.html { render :action => "new" }
#         format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
#       end
#     end
#   end

  # PUT /courses/1
  # PUT /courses/1.xml
#   def update
#     @course = Course.find(params[:id])
# 
#     respond_to do |format|
#       if @course.update_attributes(params[:course])
#         format.html { redirect_to(@course, :notice => 'Course was successfully updated.') }
#         format.xml  { head :ok }
#       else
#         format.html { render :action => "edit" }
#         format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
#       end
#     end
#   end

  # DELETE /courses/1
  # DELETE /courses/1.xml
  def destroy
    @profile = Profile.find(params[:id])
    authorize! :destroy, @profile
    
    @curriculum = @profile.curriculum
    @profile.destroy

    respond_to do |format|
      format.html { redirect_to @curriculum }
      format.xml  { head :ok }
    end
  end
end
