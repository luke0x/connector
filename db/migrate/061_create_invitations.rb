=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.column :event_id, :integer
      t.column :user_id, :integer
      t.column :calendar_id, :integer
      t.column :accepted, :boolean
    end
  end

  def self.down
    drop_table :invitations
  end
end
