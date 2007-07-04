=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateSmartGroupAttributes < ActiveRecord::Migration
  def self.up
    create_table :smart_group_attributes do |t|
      t.column :value, :string
      t.column :smart_group_id, :integer
      t.column :smart_group_attribute_description_id, :integer
    end
  end

  def self.down
    drop_table :smart_group_attributes
  end
end
