# O4
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  helper_method :current_session, :current_user, :logged_in?

  before_filter :redirect_to_ssl
  before_filter :set_locale
  before_filter :require_login?

  protected

  # Redirects from http to https if FORCE_SSL is set.
  def redirect_to_ssl
    redirect_to :protocol => "https://" if FORCE_SSL && !request.ssl?
  end

  def default_url_options(options={})
    #logger.debug "default_url_options is passed options: #{options.inspect}\n"
    #hash = { :locale => I18n.locale }

    #if @curriculum # params[:curriculum_id]
    #  hash[:curriculum_id] = @curriculum #params[:curriculum_id]
    #end

    return { :locale => I18n.locale }
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

  private

  def current_session
    return @current_session if defined?(@current_session)
    @current_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_session && current_session.record
  end

  def logged_in?
    !!current_user
  end

  # If require_login GET-parameter is set, this filter redirects to login. After a successful login, user is redirected back to the original location.
  def require_login?
    login_required if params[:require_login] && !logged_in?
  end
  
  # Before filter that ensures that user is authenticated
  def login_required
    return if current_user
      
    redirect_to_login
    return false
  end
  alias_method :authenticate_user, :login_required

  # Handle authorization failure
  rescue_from CanCan::AccessDenied do |exception|
    if request.xhr?
      head :forbidden
    elsif logged_in?
      render :template => 'shared/forbidden', :status => 403
    else
      redirect_to_login
    end
  end
  
  def redirect_to_login
    respond_to do |format|
      format.html do
        store_location

        if defined?(SHIB_ATTRIBUTES)
          #if request.env[SHIB_ATTRIBUTES[:id]]
            # If Shibboleth headers are present, redirect directly to session creation
          #  redirect_to shibboleth_session_path
          #else
            # If Shibboleth headers are not present, redirect to IdP
            redirect_to SHIB_PATH + shibboleth_session_url(:protocol => 'https')
          #end
        else
          redirect_to new_session_url
        end
      end
      format.any do
        request_http_basic_authentication 'Web Password'
      end
    end
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

end
