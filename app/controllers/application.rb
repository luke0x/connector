=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ApplicationController < ActionController::Base
  include ExceptionNotifiable

  # session :session_key => '_connector_session_id'

  localize_with_gettext 'connector'

  before_filter :capture_start_time
  before_filter :set_mysql_charset
  before_filter :pre_clean
  before_filter :en_locale
  before_filter :load_domain
  before_filter :load_organization
  before_filter :load_application
  after_filter  :log_request
  
  helper_method :current_domain
  helper_method :current_organization  
  helper_method :current_user
  helper_method :selected_user
  
  def connector_languages
    if JoyentConfig.staging_servers.include?(request.env['SERVER_NAME'])
      JoyentConfig.production_languages + JoyentConfig.development_languages
    else
      JoyentConfig.production_languages
    end
  end
  helper_method :connector_languages

  private  
    def current_domain
      @current_domain ||= Domain.find_by_web_domain(request.host)
    end             
    
    def current_domain=(value)
      @current_domain = value
    end
              
    def current_organization
      @current_domain && @current_domain.organization
    end           
    
    def current_user
      User.current
#      @current_user ||= current_organization.users.find(LoginToken.current.user_id) rescue nil
    end     
    
    def current_user=(value)
      User.current = value
      #@current_user = value
    end     
    
    def selected_user
      @selected_user ||= current_user
    end
    
    def selected_user=(value)
      @selected_user = value
    end
    
    def capture_start_time
      @log_start_time = Time.now
      true
    end

    def set_mysql_charset
      suppress(ActiveRecord::StatementInvalid) do
        ActiveRecord::Base.connection.execute "SET NAMES 'utf8' COLLATE 'utf8_general_ci'"
      end
    end

    def pre_clean
      User.current = nil
      List.current = nil
        
      self.current_domain = nil
      self.current_user   = nil
      self.selected_user  = nil
      true
    end

    # always login with english until we save language in a cookie
    def en_locale
      GetText.locale = 'en'
      Date.translate_strings
      GetText.locale
    end

    def load_domain
      unless current_domain
        if ! request.host.blank? and request.host.split('.').size == 2
          redirect_to affiliate_login_url(:affiliate => params[:affiliate] || Affiliate.find(1).name)
        else
          redirect_to '/noaccount.html'
        end
        false
      end
    end

    def load_organization
      if current_organization.blank? || !current_organization.active?
        redirect_to '/deactivated.html'
        false
      else
        true
      end
    end
  
    def load_application
      @application_name = self.controller_name
    end

    def log_request
      UserRequest.create(:user_id      => LoginToken.current ? LoginToken.current.user_id : '',
                         :organization => current_organization ? current_organization.name : '',
                         :action       => "#{self.class.to_s}##{action_name}",
                         :duration     => (Time.now - @log_start_time) * 1000,
                         :session_id   => (session.is_a?(Hash) ? '' : session.session_id),
                         :username     => (current_user ? current_user.username : ''))
    end

    def redirect_back_or_home
      if request.env.has_key?("HTTP_REFERER")
        redirect_to(:back)
      else
        redirect_to(connector_home_url)
      end
    end

end
