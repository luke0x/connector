=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MessageJoyentIdActive < ActiveRecord::Migration
  def self.up
    add_column "messages", "joyent_id", :string
    add_column "messages", "active", :boolean, :default => true
  end

  def self.down
    remove_column "messages", "joyent_id"
    remove_column "messages", "active"
  end
end
