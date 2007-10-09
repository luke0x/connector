=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddAlarmForEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :alarm_trigger_in_minutes, :integer
  end

  def self.down
    remove_column :events, :alarm_trigger_in_minutes
  end
end
