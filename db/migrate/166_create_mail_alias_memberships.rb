=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateMailAliasMemberships < ActiveRecord::Migration
  def self.up
    create_table :mail_alias_memberships do |t|
      t.column :user_id,       :integer
      t.column :mail_alias_id, :integer
      t.column :created_at,    :datetime
      t.column :updated_at,    :datetime
    end
  end

  def self.down
    drop_table :mail_alias_memberships
  end
end
