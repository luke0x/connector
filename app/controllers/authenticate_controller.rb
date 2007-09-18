=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AuthenticateController < PublicController
  layout nil
  localize_with_gettext 'connector'
  
  before_filter :load_domain,       :except => 'affiliate_login'
  before_filter :load_organization, :except => 'affiliate_login'

  # explicitly set to the connector 'home page'
  def index
    redirect_to connector_home_url
  end
  
  def affiliate_login
    @affiliate = Affiliate.find_by_name(params[:affiliate]) || Affiliate.find(1)  
  end
  
  def login
    # first try the sso stuff
    if session[:sso_verified] and request.cookies['sso_token_value'] and LoginToken.current = LoginToken.find_by_value(request.cookies['sso_token_value'])
      current_user = current_organization.users.find(LoginToken.current.user_id)

      redirect_to connector_home_url and return
    # more sso see if they have a remember cookie
    elsif request.cookies['sso_remember'] and request.cookies['sso_remember'][0] == 'true' and request.cookies['sso_token_value'] and LoginToken.current = LoginToken.find_for_cookie(request.cookies['sso_token_value'][0])
      session[:sso_verified] = true
      current_user = current_organization.users.find(LoginToken.current.user_id)

      redirect_to connector_home_url and return
    elsif request.post? and user = current_domain.authenticate_user(params[:username], params[:password])
      return set_user_credentials(user)
    elsif ! request.post?
      return
    else
      flash[:login_error] = _('Invalid username or password.')
    end
  end
  
  def verify
    LoginToken.current = LoginToken.find_for_sso(params[:token])

    session[:sso_verified]    = true
    cookies['sso_token_value'] = {:value => LoginToken.current.value, :expires => Time.now + 2.weeks}

    redirect_to connector_home_url
  end

  def logout
    if request.cookies['sso_token_value'] and token = LoginToken.find_by_value(request.cookies['sso_token_value'])
      token.destroy
    end
    if current_user and current_user.login_token
      current_user.login_token.destroy
    end
    cookies.delete 'sso_remember'
    cookies.delete 'sso_token_value'
    reset_session

    redirect_to login_url
  end
  
  def reset_password
    return unless request.post?
    
    if user = current_organization.users.find_by_username(params[:username]) and ! user.recovery_email.blank?
      user.reset_password!
      flash[:message] = "Recovery email sent to '#{user.recovery_email}.' Click the link in the email to reset your password."
    else
      flash[:error] = "Password recovery for '#{params[:username]}' is unavailable. No email sent."
    end
  end
  
  def verify_reset_password
    unless params.has_key?(:token)
      redirect_to logout_url and return
    end
    unless user = User.find_by_recovery_token(params[:token])
      redirect_to logout_url and return
    end

    if request.post? and user.update_password(params[:password], params[:password_confirmation])
      user.save!
      return set_user_credentials(user)
    elsif request.post?
      flash[:error] = "An error occurred, please try again."
      redirect_to :back and return
    end
  end
  
  private
  
    def set_user_credentials(user)
      current_user = user

      session[:sso_verified]     = true
      LoginToken.current         = current_user.create_login_token
      cookies['sso_token_value'] = {:value => LoginToken.current.value, :expires => Time.now + 2.weeks}
      if params[:sso_remember]
        cookies['sso_remember'] = {:value => 'true', :expires => Time.now + 2.weeks}
      else
        cookies.delete 'sso_remember'
      end

      if current_organization.partner?
        redirect_to session[:post_login_url] || lightning_portal_url
      else
        redirect_to session[:post_login_url] || connector_home_url
      end
    end
end