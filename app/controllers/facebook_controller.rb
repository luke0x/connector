=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class FacebookController < ApplicationController
  layout nil

  skip_before_filter :load_domain
  skip_before_filter :load_organization

  before_filter      :require_facebook_login,         :only => [:index, :login, :dismiss]
  before_filter      :ensure_connected_facebook_user, :only => [:index, :dismiss]

  def index
    return redirect_to(facebook_canvas_url) unless in_facebook_canvas?

    @notifications = current_user.current_notifications.find(:all,
                                                             :include => {:notifier => [:person]},
                                                             :order   => "notifications.created_at DESC")
  end

  def dismiss
    if params[:id] && notification = current_user.notifications.find(params[:id])
      notification.acknowledge!
    end

    @notifications = current_user.current_notifications.find(:all,
                                                             :include => {:notifier => [:person]},
                                                             :order   => "notifications.created_at DESC")

    render :partial => "notifications_table"
  end

  def login
    if request.post?
      self.current_domain = Domain.find_by_web_domain(params[:subdomain].strip)

      if current_domain && self.current_user = current_domain.authenticate_user(params[:username], params[:password])
        current_user.update_attributes(:facebook_uid => session[:facebook_uid], :facebook_session_key => session[:facebook_session_key])
        current_user.update_facebook_profile!

        return redirect_to(facebook_canvas_url)
      else
        flash[:login_error] = _('Invalid subdomain, username or password.')
      end
    else
      session[:facebook_uid]         = fbsession.session_user_id
      session[:facebook_session_key] = fbsession.session_key
    end

    @facebook_user = fbsession.users_getInfo(:uids => [fbsession.session_user_id], :fields => ['first_name', 'last_name'])
  end

  def remove
    # This should really be dealt with in the rails facebook plugin because
    #  I am not verifying that this is really from facebook
    setup_facebook_user(params[:fb_sig_user])

    current_user.update_attributes(:facebook_uid => nil, :facebook_session_key => nil) if current_user

    render :nothing => true
  end

  private

  def ensure_connected_facebook_user
    setup_facebook_user(fbsession.session_user_id)

    redirect_to(facebook_login_url)  unless current_user
  end

  def setup_facebook_user(facebook_uid)
    if user = User.find_by_facebook_uid(facebook_uid)
      self.current_user   = user
      self.current_domain = user.organization.primary_domain
    end
  end

  def finish_facebook_login
  end

  def facebook_canvas_url
    "http://apps.facebook.com#{facebook_canvas_path}"
  end
end