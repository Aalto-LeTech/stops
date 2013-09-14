class Curriculums::RolesController < CurriculumsController
  before_filter :login_required
  before_filter :load_curriculum
  
  def load_curriculum
    @curriculum = Curriculum.find(params[:curriculum_id])
    authorize! :update, @curriculum
  end
  
  def new
    @invitations = TeacherInvitation.where(:target_id => @curriculum.id).all
    @subject = t("curriculums.roles.new.subject_default")
    @content = t("curriculums.roles.new.mail_template")
  end
  
  def create
    unless params[:addresses].blank?
      Curriculum.delay.invite_teachers(@curriculum.id, params[:addresses].split(/[,\s]/), params[:subject], params[:content])
    end
    
    #render :action => :new
    flash[:success] = t('curriculums.roles.new.sent_success')
    redirect_to curriculum_path(@curriculum)
  end
  
  def destroy
    user = User.find(params[:id])
    
    CurriculumRoles.where(:user_id => user.id, :target_id => @curriculum.id, :role => 'teacher').delete
    
    respond_to do |format|
      #format.html { redirect_to course_teachers_path(@course) }
      format.json { render :json => [user.id].as_json }
    end
  end
end
 
