# O4
class SessionsController < ApplicationController
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    
    session[:logout_url] = nil
    
    if @user_session.save
      # TODO: log username
      logger.info "Login successful" # "Logged in #{@user_session}"
      redirect_back_or_default root_url
    else
      logger.info "Login failed. #{@user_session.errors.full_messages.join(',')}"
      
      flash[:error] = "#{@user_session.errors.full_messages.join('. ')}"
      render :action => :new
    end
  end
  
  def destroy
    return unless current_session
    
    logout_url = session[:logout_url]
    current_session.destroy
    flash[:success] = I18n.t(:sessions_logout_message)
    
    if logout_url
      redirect_to(logout_url)
    else
      redirect_to(root_url)
    end
  end
  
  
  def shibboleth
    shibinfo = {
      :login => request.env[SHIB_ATTRIBUTES[:id]],
      :studentnumber => (request.env[SHIB_ATTRIBUTES[:studentnumber]] || '').split(':').last,
      :firstname => request.env[SHIB_ATTRIBUTES[:firstname]],
      :lastname => request.env[SHIB_ATTRIBUTES[:lastname]],
      :email => request.env[SHIB_ATTRIBUTES[:email]],
      :affiliation => request.env[SHIB_ATTRIBUTES[:affiliation]]
    }
    logout_url = request.env[SHIB_ATTRIBUTES[:logout]]

#     shibinfo = {
#       :login => '00002', #'student1@hut.fi',
#       :studentnumber => ('urn:mace:terena.org:schac:personalUniqueCode:fi:tkk.fi:student:00002' || '').split(':').last,
#       :firstname => 'Teemu',
#       :lastname => 'Teekkari',
#       :email => 'tteekkar@cs.hut.fi',
#       :organization => 'hut.fi'
#     }
#     logout_url= 'http://www.aalto.fi/'
    
    shibboleth_login(shibinfo, logout_url)
  end
  

  def shibboleth_login(shibinfo, logout_url)
    if shibinfo[:login].blank? && shibinfo[:studentnumber].blank?
      flash[:error] = "Shibboleth login failed (no studentnumber or username received)."
      logger.warn("Shibboleth login failed (missing attributes). #{shibinfo}")
      render :action => 'new'
      return
    end
    
    # Find user by username (eppn)
    unless shibinfo[:login].blank?
      logger.debug "Trying to find by login #{shibinfo[:login]}"
      user = User.find_by_login(shibinfo[:login])
    end

    # If user was not found by login, search with student number. (User may have been created as part of a group, but has never actually logged in.)
    # Login must be null, otherwise the account may belong to someone else from another organization.
    #if !user && !shibinfo[:studentnumber].blank?
    #  logger.debug "Trying to find by studentnumber #{shibinfo[:studentnumber]}"
    #  user = User.find_by_studentnumber(shibinfo[:studentnumber], :conditions => "login IS NULL")
    #end

    # Create new account or update an existing
    unless user
      logger.debug "User not found. Trying to create."
      
      # New user
      user = User.new()
      shibinfo.each do |key, value|
        user.write_attribute(key, value)
      end
      user.reset_persistence_token
      user.reset_single_access_token
      if user.save(:validate => false)
        logger.info("Created new user #{user.login} (#{user.studentnumber}) (shibboleth)")
      else
        logger.info("Failed to create new user (shibboleth) #{shibinfo} Errors: #{user.errors.full_messages.join('. ')}")
        flash[:error] = "Failed to create new user. #{user.errors.full_messages.join('. ')}"
        render :action => 'new'
        return
      end
    else
      logger.debug "User found. Updating attributes."
      
      # Update metadata
      shibinfo.each do |key, value|
        user.write_attribute(key, value) if user.read_attribute(key).blank?
      end
      
      user.reset_persistence_token if user.persistence_token.blank?  # Authlogic won't work if persistence token is empty
      user.reset_single_access_token if user.single_access_token.blank?
    end

    # Create session
    if UserSession.create(user)
      session[:logout_url] = logout_url
      logger.info("Logged in #{user.login} (#{user.studentnumber}) (shibboleth)")
      
      redirect_back_or_default root_url
    else
      logger.warn("Failed to create session for #{user.login} (#{user.studentnumber}) (shibboleth)")
      flash[:error] = 'Shibboleth login failed.'
      render :action => 'new'
    end
  end
end
