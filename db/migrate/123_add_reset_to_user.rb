=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddResetToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :recovery_token, :string, :default => ""
  end

  def self.down
    remove_column :users, :recovery_token
  end
end
