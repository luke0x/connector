=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)
class GetEventsReadyForAlarms < ActiveRecord::Migration
  def self.up
    add_column :events, :next_fire, :datetime
    add_column :events, :fired, :boolean
  end

  def self.down
    remove_column :events, :next_fire
    remove_column :events, :fired
  end
end
