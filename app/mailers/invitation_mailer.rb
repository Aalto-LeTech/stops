class InvitationMailer < ActionMailer::Base
  default :from => EMAIL_FROM
  default_url_options[:host] = EMAIL_HOST_PREFIX
  default_url_options[:protocol ] = 'https://'
  
  def teacher_invitation(invitation, subject, message)
    @message = message.gsub('%INVITATION%', invitation_url(:id => invitation.token)).gsub('%FRONTPAGE%', root_url())
    mail(:to => invitation.email, :subject => subject)
  end
  
end
