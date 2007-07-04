=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateListColumns < ActiveRecord::Migration
  def self.up
    create_table :list_columns do |t|
      t.column :list_id, :integer
      t.column :position, :integer
      t.column :name, :string
      t.column :kind, :string
    end
  end

  def self.down
    drop_table :list_columns
  end
end