=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateGuestPaths < ActiveRecord::Migration
  def self.up
    create_table :guest_paths do |t|
      t.column :user_id, :integer
      t.column :guest_id, :integer
      t.column :relative_path, :string
    end
  end

  def self.down
    drop_table :guest_paths
  end
end
