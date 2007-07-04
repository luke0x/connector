=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddJajahCredentialsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :jajah_username, :string
    add_column :users, :jajah_password, :string
  end

  def self.down
    remove_column :users, :jajah_username
    remove_column :users, :jajah_password
  end
end
