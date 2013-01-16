class InvitationMailer < ActionMailer::Base
  default :from => EMAIL_FROM
  default_url_options[:host] = EMAIL_HOST_PREFIX
  
  def teacher_invitation(invitation_id, subject, message)
    @invitation = Invitation.find(invitation_id)
    
    @message = message.gsub('LINK', invitation_url(:id => @invitation.token, :protocol => 'https://'))
    
    mail(:to => @invitation.email, :subject => subject)
  end
  
end
