class UsersController < ApplicationController
  respond_to :json, :only => 'courses'

  # render new.rhtml
  def new
    @user = User.new
  end
  
  def edit
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end
  end
 
  def create
    #logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    #if success && @user.errors.empty?
            # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      #self.current_user = @user # !! now logged in
      #redirect_back_or_default('/')
      #flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    #else
    #  flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
    #  render :action => 'new'
    #end
  end
  
  def courses
    # TODO: authorization
    @user = User.find(params[:id])
    user_courses = @user.user_courses.joins(:course_instance, :scoped_course).select('code, scoped_course_id, period_id')
    #prereqs = CoursePrereq.where(:requirement => STRICT_PREREQ).joins('INNER JOIN scoped_courses AS course ON course.id = course_prereqs.scoped_course_id INNER JOIN scoped_courses AS prereq ON prereq.id = course_prereqs.scoped_prereq_id').where("course.curriculum_id = ?", @curriculum).select('course.code AS course_code, prereq.code AS prereq_code, course.id')
    
    respond_to do |format|
      format.json { render :json => user_courses.to_json }
    end
    
  end
end
