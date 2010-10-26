# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :passwod_confirmation
  
  before_filter :redirect_to_ssl
  before_filter :set_locale
  before_filter :load_css
  #before_filter :load_javascripts
  before_filter :require_login?
  
  protected
  
  # Redirects from http to https if FORCE_SSL is set.
  def redirect_to_ssl
    redirect_to :protocol => "https://" if FORCE_SSL && !request.ssl?
  end
  
  def default_url_options(options={})
    #logger.debug "default_url_options is passed options: #{options.inspect}\n"
    hash = { :locale => I18n.locale }
    
    if @curriculum # params[:curriculum_id]
      hash[:curriculum_id] = @curriculum #params[:curriculum_id]
    end
    
    return hash
  end 
    
  # Sets the locale based on params and user preferences.
  def set_locale
    if params[:locale]  # Locale is given as a URL parameter
      I18n.locale = params[:locale]
      
      # Save the locale into session
      session[:locale] = params[:locale]

      # Save the locale in user's preferences
      #if user_signed_in?
      #  current_user.locale = params[:locale]
      #  current_user.save
      #end
    #elsif logged_in? && !current_user.locale.blank?  # Get locale from user's preferences
    #  I18n.locale = current_user.locale
    elsif !session[:locale].blank?  # Get locale from session
      I18n.locale = session[:locale]
    end
  end
  
  # Loads extra CSS stylesheets.
  def load_css
    @stylesheets = ['default']
    
    if File.exists?(File.join(RAILS_ROOT, 'public', 'stylesheets', controller_name + '.css'))
      @stylesheets << controller_name
    end
  end
  
  # Loads extra javascripts
  def load_javascripts
    @javascripts = []
    
    if File.exists?(File.join(RAILS_ROOT, 'public', 'javascripts', controller_name + '.js'))
      @javascripts << controller_name
    end
  end
  
  def load_curriculum
    @curriculum = Curriculum.find(params[:curriculum_id])
  end
  
  def load_profile
    @profile = Profile.find(params[:profile_id])
  end
  
  # Sends email to admin if an exception occurrs. Recipient is defined by the ERRORS_EMAIL constant.
  def log_error(exception)
    super(exception)

    begin
      # Send email
      if ERRORS_EMAIL && !(local_request? || exception.is_a?(ActionController::RoutingError))
        ErrorMailer.deliver_snapshot(exception, clean_backtrace(exception), params, request)
      end
    rescue => e
      logger.error(e)
    end
  end

  # If require_login GET-parameter is set, this filter redirect to login. After successful login, the user is redirected back to the original location.
  def require_login?
    authenticate_user! if params[:require_login] && !user_signed_in?
  end
  
  # Handle authorization failure
  rescue_from CanCan::AccessDenied do |exception|
    unless user_signed_in?
      # If user is not authenticated, redirect to login
      authenticate_user!
    else
      # If user is authenticated, show "Forbidden"
      render :template => "shared/forbidden", :status => 403
    end
  end

  
end
