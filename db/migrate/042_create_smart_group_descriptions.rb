=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateSmartGroupDescriptions < ActiveRecord::Migration
  def self.up
    create_table :smart_group_descriptions do |t|
      t.column :name, :string
      t.column :item_type, :string
    end
  end

  def self.down
    drop_table :smart_group_descriptions
  end
end
