=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MoveToEndDateForEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :end_time, :timestamp
    execute("UPDATE events SET end_time = (start_time + (duration * '1 second'::interval))")
    remove_column :events, :duration
  end

  def self.down
    add_column :events, :duration, :integer
    execute("UPDATE events SET duration = (extract(epoch from end_time) - extract(epoch from start_time))")
    remove_column :events, :end_time
  end
end
