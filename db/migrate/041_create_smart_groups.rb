=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateSmartGroups < ActiveRecord::Migration
  def self.up
    create_table :smart_groups do |t|
      t.column :name, :string
      t.column :smart_group_description_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :smart_groups
  end
end
