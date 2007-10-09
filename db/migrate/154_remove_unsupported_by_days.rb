=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# remove unsupported by_day values

class RemoveUnsupportedByDays < ActiveRecord::Migration
  def self.up
    events = Event.find(:all)
    events = events.reject{|e| e.by_day.blank?}
    events = events.reject do |e|
      e.by_day.all?{|i| ['su','mo','tu','we','th','fr','sa'].include?(i)}
    end
    events.each do |e|
      e.update_attribute(:by_day, nil)
    end
  end

  def self.down
  end
end