class Curriculums::RolesController < CurriculumsController
  before_filter :login_required
  before_filter :load_curriculum
  
  def load_curriculum
    @curriculum = Curriculum.find(params[:curriculum_id])
    authorize! :edit, @curriculum
  end
  
  def index
    @invitations = TeacherInvitation.where(:target_id => @curriculum.id).all
  end
  
  def new
    @subject = t("curriculums.roles.new.subject_default")
    @content = t("curriculums.roles.new.mail_template")
  end
  
  def create
    @subject = params[:subject]
    @addresses = params[:addresses]
    @content = params[:content]
    
    render :action => :new
#     added_users = []
#     invited_users = []
#     
#     # Add by user_id
#     if params[:user_id]
#        # FIXME
#       user_ids = params[:user_id].split(',').map {|u| u.strip.to_i}
#       users_to_add = User.find(user_ids) - @course.teachers
#       @course.teachers << users_to_add
#       
#       added_users.concat(users_to_add)
#     end
#     
#     # Invite by email
#     if params[:email]
#       emails = params[:email].split(',')
#       
#       emails.each do |address|
#          # FIXME
#         invitation = TeacherInvitation.create(:target_id => @course.id, :email => address.strip, :expires_at => Time.now + 1.weeks)
#         InvitationMailer.delay.teacher_invitation(invitation.id)
#         
#         invited_users << {id: invitation.id, email: address}
#       end
#     end
#     
#     response = { added_users: added_users.as_json(:only => [ :id, :firstname, :lastname, :email ]), invited_users: invited_users }
#     
#     respond_to do |format|
#       #format.html { redirect_to course_teachers_path(@course) }
#       format.json { render :json => response }
#     end
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
 
