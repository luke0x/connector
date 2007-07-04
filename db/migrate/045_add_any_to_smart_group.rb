=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddAnyToSmartGroup < ActiveRecord::Migration
  def self.up
    add_column :smart_groups, :accept_any, :boolean
  end

  def self.down
    remove_column :smart_groups, :accept_any
  end
end
