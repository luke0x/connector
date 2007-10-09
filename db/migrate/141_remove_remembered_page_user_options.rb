=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RemoveRememberedPageUserOptions < ActiveRecord::Migration
  def self.up
    UserOption.find(:all, :conditions => ["user_options.key LIKE ?", "% Last Page"]).map(&:destroy)
    UserOption.find(:all, :conditions => ["user_options.key = ?", 'Connector Last Application']).map(&:destroy)
  end

  def self.down
    # n/a
  end
end