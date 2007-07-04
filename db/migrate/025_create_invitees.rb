=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateInvitees < ActiveRecord::Migration
  def self.up
    create_table :invitees do |t|
      t.column :event_id,  :integer
      t.column :person_id, :integer
      t.column :accepted,  :boolean
    end
  end

  def self.down
    drop_table :invitees
  end
end
