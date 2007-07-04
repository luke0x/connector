=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

require 'digest/sha1'

class AdminController < ActionController::Base
  before_filter :auth, :except => [:heartbeat]
  layout 'admin'
  
  # SHA1 hash 
  @@http_user  = JoyentConfig.admin_http_user
  @@http_pass  = JoyentConfig.admin_http_password
  @@secure_pass= JoyentConfig.admin_secure_password
  
  QUERY_UNITS = ['second', 'minute', 'hour', 'day', 'week', 'month', 'year']
  
  def heartbeat
    render :text => 'alive'
  end

  def index
  end

  def login
    return true unless request.post?

    if params[:password] and Digest::SHA1.hexdigest(params[:password]) == @@secure_pass
      session[:authed] = true
      redirect_to :controller => 'admin', :action => 'index'
    else
      session[:authed] = nil
    end
  end

  def logout
    session[:authed] = nil
    redirect_to :controller => 'admin', :action => 'index'
  end

  def set_query_params
    session[:admin_query_unit]  = params[:unit]
    session[:admin_query_value] = params[:value]
    
    render :text => "New query range set - #{query_interval}", :layout => false  
  end
  
  def slowest_evar
    @title = 'slowest evar'
    @results = ActiveRecord::Base.connection.execute("select action, duration, organization, d.email_domain as sitename, ur.username from user_requests ur, users u, domains d where ur.user_id = u.id and u.organization_id = d.organization_id and d.primary = 1 and ur.created_at > (now() - interval #{query_interval}) order by 2 desc limit 25;")
    render :action => 'results', :layout => false
  end

  def slowest_average
    @title = 'slowest average'
    @results = ActiveRecord::Base.connection.execute("select action, avg(duration), count(*) from user_requests ur where ur.created_at > (now() - interval #{query_interval}) group by action order by 2 desc limit 25;")
    render :action => 'results', :layout => false
  end

  def most_popular
    @title = 'most popular hits'
    @results = ActiveRecord::Base.connection.execute("select action, count(*) from user_requests ur where ur.created_at > (now() - interval #{query_interval}) group by action order by 2 desc limit 25;")
    render :action => 'results', :layout => false
  end

  def most_active
    @title = 'most active orgs'
    @results = ActiveRecord::Base.connection.execute("select organization, d.email_domain as sitename, count(*) from user_requests ur, users u, domains d where ur.user_id = u.id and u.organization_id = d.organization_id and d.primary = 1 and ur.created_at > (now() - interval #{query_interval}) group by 1, 2 order by 3 desc limit 25;")
    render :action => 'results', :layout => false
  end

  def most_active_users
    @title = 'most active users'
    @results = ActiveRecord::Base.connection.execute("select ur.username, organization, d.email_domain as sitename, count(*) from user_requests ur, users u, domains d where ur.user_id = u.id and u.organization_id = d.organization_id and d.primary = 1 and ur.created_at > (now() - interval #{query_interval}) group by 1, 2, 3 order by 4 desc limit 25;")
    render :action => 'results', :layout => false
  end
  
  def organization_info
    @title = 'organization info'
    @organization = Organization.find(params[:organization_id]) rescue Organization.find(:first, :order => 'name')
    render :action => 'organization_info', :layout => false
  end
  
  def svn_revision
    render :text => `svn info | grep Revi`, :layout => false
  end
     
  private

    def auth
      # only accessible via a domain like admin.joyent.net
      unless request.host =~ /^admin\./      
        redirect_to '/404.html' 
        return false                           
      end
    
      # If we have already authenticated, just return
      # I don't love this here, but the ajax requests wouldn't load without it
      return true if session[:authed]
    
      # Require HTTP AUTH   
      if (auth = request.env['X-HTTP_AUTHORIZATION'] || request.env['HTTP_AUTHORIZATION'])
        auth = auth.split
        user, password = Base64.decode64(auth[1]).split(':')[0..1]
      
        if Digest::SHA1.hexdigest(user) == @@http_user && Digest::SHA1.hexdigest(password) == @@http_pass
          redirect_to :controller => 'admin', :action => 'login' unless action_name == 'login'
          return true
        end
      end
    
      response.headers["Status"] = "Unauthorized"
      response.headers["WWW-Authenticate"] = "Basic realm=\"Admin Panel\""
      render :text => 'You must log in to access the admin panel', :status => 401
      return false    
    end
  
    def query_interval
      unit  = QUERY_UNITS.include?(session[:admin_query_unit]) ? session[:admin_query_unit] : 'week'
      value = session[:admin_query_value].to_i > 0 ? session[:admin_query_value].to_i : 1
    
      @query_interval = "#{value} #{unit}"
    end
end