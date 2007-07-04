=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateUsers < ActiveRecord::Migration
  def self.up
    remove_column :people, :is_admin
    
    create_table :users do |t|
      t.column :person_id,     :integer
      t.column :username,      :string
      t.column :password,      :string
      t.column :password_sha1, :string
      t.column :admin,         :boolean, :default => false, :null => false
    end
  end

  def self.down
    drop_table :users
    
    add_column    :people, :is_admin, :boolean
  end
end
