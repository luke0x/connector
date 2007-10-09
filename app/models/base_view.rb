=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class BaseView
  attr_reader :date, :start_time, :end_time, :current_user

  def initialize(date, start_time, end_time, current_user)
    @events        = []
    @others_events = {} # key: user_id, value: array of events
    @date          = date
    @start_time    = start_time
    @end_time      = end_time
    @current_user  = current_user
  end

  def events
    @events.sort!
  end

  def each(&block)
  end

  def others_events
    @others_events
  end
end