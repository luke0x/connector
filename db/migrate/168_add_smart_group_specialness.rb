=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddSmartGroupSpecialness < ActiveRecord::Migration
  def self.up
    add_column "smart_groups", "special", :boolean, :default => false
  end

  def self.down
    remove_column "smart_groups", "special"
  end
end
