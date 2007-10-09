=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AuthKeyController < ActionController::Base
  session :off
  
  def key
    org = Domain.find_by_web_domain(request.host).organization
    
    user = org.users.find_by_username(params[:username])
    
    key = AuthKey.generate(org, user, params[:password])
    
    headers['Content-Type'] = 'text/plain'
    render :text => key.key
  rescue
    response.headers["Status"] = "Unauthorized"
    response.headers["WWW-Authenticate"] = "Basic realm=\"Auth Key API\""
    render :text => 'Invalid username or password', :status => 401
  end
end
