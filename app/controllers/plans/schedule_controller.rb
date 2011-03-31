# Study plan controller
class Plans::ScheduleController < PlansController

  before_filter :authenticate_user

  before_filter :load_plan
  
  
  
  
  def show
    @periods = @user.relevant_periods
    @curriculum = Curriculum.first # FIXME: @user.curriculum
    

    @courses = @user.courses # returns a list of AbstractCourses
    #@courses = Course.semesters(@user.courses) 
    
    #@credits = UserCourse.sum('credits', :include => :abstract_course, :conditions => ['user_id=?', @user.id])
    
  end
  
  def edit
  end

  
end
