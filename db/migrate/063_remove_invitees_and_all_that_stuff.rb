=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RemoveInviteesAndAllThatStuff < ActiveRecord::Migration
  def self.up
    drop_table :invitees
    remove_column :events, :calendar_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
