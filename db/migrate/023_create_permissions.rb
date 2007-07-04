=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.column :person_id,         :integer
      t.column :item_id,           :integer
      t.column :item_type,         :string
    end
  end

  def self.down
    drop_table :permissions
  end
end
