=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddListRowDepth < ActiveRecord::Migration
  def self.up
    add_column :list_rows, :depth_cache, :integer
    ListRow.find(:all).each{|lr| lr.update_attribute(:depth_cache, lr.depth)}
  end

  def self.down
    remove_column :list_rows, :depth_cache
  end
end