=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class FixMissingDates < ActiveRecord::Migration
  def self.up
    Message.find(:all, :conditions => 'date is null').each{|m| m.update_attribute(:date, m.internaldate)}
  end

  def self.down
  end
end
