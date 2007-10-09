=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class StubEvent
  attr_accessor :start_time_in_user_tz
  def initialize(event, start_time)
    @event = event
    self.start_time_in_user_tz = start_time
  end
  
  def method_missing(name, *args)
    @event.send(name, *args)
  end  
  
  def respond_to?(name)
    super.respond_to?(name) || @event.respond_to?(name)  
  end
  
  def id
    @event.id
  end
  
  def falls_on?(date)
    Event.falls_on?(self, date)
  end

  def between?(local_start_time, local_end_time)
    Event.between?(self, local_start_time, local_end_time)
  end
  
  def end_time_in_user_tz
    @__etiutz ||= (@start_time_in_user_tz + self.duration)
  end
end