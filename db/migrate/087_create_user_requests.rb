=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateUserRequests < ActiveRecord::Migration
  def self.up
    create_table :user_requests do |t|
      t.column :user_id, :string
      t.column :organization, :string
      t.column :username, :string
      t.column :action, :string
      t.column :created_at, :datetime
      t.column :duration, :integer # milliseconds
      t.column :session_id, :string
    end
  end

  def self.down
    drop_table :user_requests
  end
end
