=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateLists < ActiveRecord::Migration
  def self.up
    create_table :lists do |t|
      t.column :organization_id, :integer
      t.column :user_id, :integer
      t.column :name, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :list_folder_id, :integer
    end
  end

  def self.down
    drop_table :lists
  end
end