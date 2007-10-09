=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RemoveIconUrl < ActiveRecord::Migration
  def self.up
    remove_column :people, :icon_url
  end

  def self.down
    add_column :people, :icon_url, :string, :default => ''
  end
end
