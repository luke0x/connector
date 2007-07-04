=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

# 052 beat you to it
class UndoDismissNotifications < ActiveRecord::Migration
  def self.up
    remove_column :notifications, :dismissed
    add_column :notifications, :created_at, :datetime
    add_column :notifications, :updated_at, :datetime
  end

  def self.down
    add_column :notifications, :dismissed, :boolean, :default=>false
    remove_column :notifications, :created_at
    remove_column :notifications, :updated_at
  end
end