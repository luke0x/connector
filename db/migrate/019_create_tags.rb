=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.column :name, :string
      t.column :organization_id, :integer
    end
  end

  def self.down
    drop_table :tags
  end
end
