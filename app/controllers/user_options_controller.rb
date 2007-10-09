=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class UserOptionsController < AuthenticatedController
  def set
    return unless params.has_key?(:key)
    return unless params.has_key?(:value)
    current_user.set_option(params[:key], params[:value])
    render :nothing => true
  end
  
  private
  
  def verify_app_enabled
    true
  end
end