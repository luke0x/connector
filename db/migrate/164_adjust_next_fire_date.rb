=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AdjustNextFireDate < ActiveRecord::Migration
  def self.up  
    Event.update_all("fired = true") 

    Event.find(:all, :conditions => ["alarm_trigger_in_minutes > 0"]).each do |event|    
      event.send(:set_next_fire)
      event.save
    end
  end

  def self.down
  end
end
