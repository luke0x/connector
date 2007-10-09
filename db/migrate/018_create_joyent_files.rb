=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateJoyentFiles < ActiveRecord::Migration
  def self.up
    create_table :joyent_files do |t|
      t.column :organization_id, :integer
      t.column :person_id,       :integer
      t.column :pathname,        :text,     :default => ''
      t.column :size_in_bytes,   :integer,  :null => false
      t.column :notes,           :text,     :default => ''
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
    end
  end

  def self.down
    drop_table :joyent_files
  end
end
