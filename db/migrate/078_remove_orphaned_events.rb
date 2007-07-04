=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class RemoveOrphanedEvents < ActiveRecord::Migration
  def self.up
    Event.find(:all).select{|e| e.calendars.first == nil}.each{|e| e.destroy}
  end

  def self.down
  end
end
