=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# if a user notified themself of one of their events, then unnotified themself,
# the event erroneously would be removed from all of their calendars

class RecreateMissingOwnerInvitations < ActiveRecord::Migration
  def self.up
    Event.find(:all).select{|e| e.calendars.select{|c| c.owner == e.owner}.length == 0}.each do |event|
      event.owner.calendars.first.add_event(event)
    end
  end

  def self.down
  end
end