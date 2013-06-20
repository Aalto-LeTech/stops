# Study plan controller
class Plans::ScheduleController < PlansController
  #respond_to :json

  before_filter :authenticate_user

  before_filter :load_plan
  
  layout 'wide'
  
  
  def show
    @periods = @user.relevant_periods
    @curriculum = Curriculum.first # FIXME: @user.curriculum
    

    @study_plan_courses = @user.study_plan.study_plan_courses
    #@courses = Course.semesters(@user.courses) 
    
    #@credits = UserCourse.sum('credits', :include => :abstract_course, :conditions => ['user_id=?', @user.id])
    
  end
  
  def edit
  end

  def update
    # TODO: authentication
    
    params[:periods].each do |user_course_id, instance_id|
      user_course = UserCourse.find(user_course_id)
      next unless user_course
        
      user_course.course_instance_id = instance_id
      user_course.save
    end
    
#     respond_to do |format|
#       format.js { render :head => :ok }
#     end
    render :text => 'ok'
  end
  
end
