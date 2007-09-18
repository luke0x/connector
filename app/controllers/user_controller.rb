=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class UserController < AuthenticatedController
  def connect
    if request.post?
      if current_user.connect_other_user(params[:web_domain], params[:username], params[:password])
        @message = _('The shortcut was created.')
      elsif request.post?
        @error = _('The shortcut could not be created. Please try again.')
      end
    end

    render :action => 'connect', :layout => false
  end
  
  def disconnect
    current_user.disconnect_other_user(User.find_by_id(params[:id]))
    
    render :action => 'connect', :layout => false
  end
  
  def switch
    new_user = current_user.switch_to(params[:id])
    domain   = new_user.organization.primary_domain.web_domain
    port     = request.port == 80 ? '' : ":#{request.port}"

    redirect_to "#{request.protocol}#{domain}#{port}/authenticate/verify?token=#{LoginToken.current.value}"
  rescue JoyentExceptions::UserNotConnectedToIdentity
    redirect_back_or_home
  end
  
  def reset_guest_password
    return unless current_user.admin?
    
    if params[:id].blank? or
       params[:person_guest_send_email].blank? or
       ! (user = current_organization.users.find_by_id(params[:id]))
      flash[:error] = "Password recovery for this guest is unavailable. No email was sent."
    else
      user.reset_password!(params[:person_guest_send_email])
      flash[:message] = "Password recovery email sent to '#{user.recovery_email}.'"
    end
  ensure
    redirect_back_or_home
  end
end