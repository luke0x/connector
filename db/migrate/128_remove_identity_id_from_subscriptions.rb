=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RemoveIdentityIdFromSubscriptions < ActiveRecord::Migration
  def self.up
    say "This can not be undone!"
    remove_column :subscriptions, :identity_id
  end

  def self.down
    add_column :subscriptions, :identity_id, :integer
  end
end
