=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateListRows < ActiveRecord::Migration
  def self.up
    create_table :list_rows do |t|
      t.column :list_id, :integer
      t.column :parent_id, :integer
      t.column :position, :integer
      t.column :children_count, :integer, :default => 0, :null => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :visible_children, :boolean, :default => true
    end
  end

  def self.down
    drop_table :list_rows
  end
end