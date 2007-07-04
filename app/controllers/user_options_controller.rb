=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class UserOptionsController < AuthenticatedController
  def set
    return unless params.has_key?(:key)
    return unless params.has_key?(:value)
    User.current.set_option(params[:key], params[:value])
    render :nothing => true
  end
  
  private
  
  def verify_app_enabled
    true
  end
end