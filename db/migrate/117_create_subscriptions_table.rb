=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateSubscriptionsTable < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.column :subscribable_id, :integer
      t.column :subscribable_type, :string
      t.column :organization_id, :integer
      t.column :user_id, :integer
      t.column :identity_id, :integer
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
