=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateAuthKeys < ActiveRecord::Migration
  def self.up
    create_table :auth_keys do |t|
      t.column :key, :string
      t.column :organization_id, :integer
      t.column :user_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :auth_keys
  end
end
