=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class HeartbeatController < ActionController::Base
  session :off
  
  def index
    User.count # Just hit the db to make sure it's OK.
    render :text => ''
  end
end
