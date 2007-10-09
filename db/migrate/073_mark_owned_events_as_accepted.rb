=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MarkOwnedEventsAsAccepted < ActiveRecord::Migration
  def self.up
    # The event owner needs to have an accepted non pending state on his invites
    # If an event invitation has a calendar associated with it, then it is accepted/non pending
    Event.find(:all).each do |event| 
      event.invitations.each do |invite|
        if event.owner == invite.user      
          invite.pending     = false if invite.pending
          invite.accepted    = true  if !invite.accepted
          invite.calendar_id = event.owner.calendars.first if !invite.calendar  
          result = invite.save
        elsif invite.calendar
          invite.pending     = false if invite.pending
          invite.accepted    = true  if !invite.accepted
          result = invite.save          
        end  
      end    
    end
  end

  def self.down
  end
end
