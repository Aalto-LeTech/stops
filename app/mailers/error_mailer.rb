class ErrorMailer < ActionMailer::Base
  default :from => EMAIL_FROM, :to => ERRORS_EMAIL
  default_url_options[:host] = EMAIL_HOST_PREFIX
  
  def snapshot(exception, params, request)
    @exception  = exception
    @params     = params
    @request    = request
    @env        = request.env

    mail(:subject => "[O4] Exception in #{request.env['REQUEST_URI']}")
  end
  
  def long_mail_queue
    mail(:subject => "[O4] Long mail queue")
  end
  
  def warning_message(subject, text)
    @text = text
    mail(:subject => "[O4] #{subject}") if ERRORS_EMAIL
  end

end
