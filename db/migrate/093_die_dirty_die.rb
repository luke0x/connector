=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class DieDirtyDie < ActiveRecord::Migration
  def self.up
    remove_column :mailboxes, :dirty
  end

  def self.down
    add_column :mailboxes, :dirty, :boolean
  end
end
