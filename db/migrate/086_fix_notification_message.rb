=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class FixNotificationMessage < ActiveRecord::Migration
  def self.up
    add_column :notifications, :message_tmp, :text
    Notification.find(:all).each do |n|
      n.message_tmp = n.message
      n.save
    end
    remove_column :notifications, :message
    rename_column :notifications, :message_tmp, :message
  end

  def self.down
    add_column :notifications, :message_tmp, :string, :default => ''
    Notification.find(:all).each do |n|
      n.message_tmp = n.message[0..254] rescue ''
      n.save
    end
    remove_column :notifications, :message
    rename_column :notifications, :message_tmp, :message
  end
end