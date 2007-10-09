=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module Notifiable
  def self.included(base)
    base.has_many :notifications, :as => :item, :dependent => :destroy, :include => :notifiee
  end

  def notified_users
    self.notifications.collect(&:notifiee).sort
  end

  def active_notifications
    self.notifications.reject(&:acknowledged)
  end
end