class UsersController < ApplicationController
  respond_to :json, :only => 'courses'

  def new
    authorize! :create, User

    @user = User.new
  end

  def edit
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end

    authorize! :update, @user
  end

  # TODO: update user

  def create
    authorize! :create, User

    @user = User.new(params[:user])
    @user.first_study_period = Period.order(:begins_at).first

    if @user.save
      flash[:notice] = "Account registered!"
      redirect_to root_url
    else
      render :action => :new
    end
  end

  def courses
    @user = User.find(params[:id])

    authorize! :read, @user

    user_courses = @user.user_courses.joins(:course_instance, :scoped_course).select('code, scoped_course_id, period_id')
    #prereqs = CoursePrereq.where(:requirement => STRICT_PREREQ).joins('INNER JOIN scoped_courses AS course ON course.id = course_prereqs.scoped_course_id INNER JOIN scoped_courses AS prereq ON prereq.id = course_prereqs.scoped_prereq_id').where("course.curriculum_id = ?", @curriculum).select('course.code AS course_code, prereq.code AS prereq_code, course.id')

    respond_to do |format|
      format.json { render :json => user_courses.to_json }
    end
  end
end
