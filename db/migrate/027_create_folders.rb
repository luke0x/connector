=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateFolders < ActiveRecord::Migration
  def self.up
    create_table :folders do |t|
      t.column :person_id, :integer
      t.column :parent_id, :integer
      t.column :name,      :string
    end
    
    add_column :joyent_files, :folder_id, :integer
  end

  def self.down
    drop_table :folders
    
    remove_column :joyent_files, :folder_id
  end
end
