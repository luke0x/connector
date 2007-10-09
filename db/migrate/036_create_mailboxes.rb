=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateMailboxes < ActiveRecord::Migration
  def self.up
    create_table :mailboxes do |t|
      t.column :name,         :string
      t.column :uid_validity, :integer
      t.column :uid_next,     :integer
      t.column :parent_id,    :integer
      t.column :user_id,      :integer 
      t.column :created_at,   :datetime
      t.column :updated_at,   :datetime
    end
  end

  def self.down
    drop_table :mailboxes
  end
end
