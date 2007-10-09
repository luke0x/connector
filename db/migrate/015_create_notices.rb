=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateNotices < ActiveRecord::Migration
  def self.up
    create_table :notices do |t|
      t.column :organization_id, :integer
      t.column :person_id,       :integer
      t.column :notifier_id,     :integer
      t.column :item_id,         :integer
      t.column :item_type,       :string
    end
  end

  def self.down
    drop_table :notices
  end
end
