=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class Invitation < ActiveRecord::Base
  validates_presence_of :event_id
  validates_presence_of :user_id

  belongs_to :event
  belongs_to :user # the invitee
  belongs_to :calendar

  def decline!
    self.pending  = false
    self.accepted = false
    self.calendar = nil
    self.save!
  end
  
  def accept!(calendar)
    raise "Must specify a calendar to accept an invitation" if calendar.blank?
    
    self.pending  = false
    self.accepted = true
    self.calendar = calendar
    self.save!
  end     
end
