=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateAccountImAddresses < ActiveRecord::Migration
  def self.up
    create_table :account_im_addresses do |t|
      t.column :person_id,  :integer
      t.column :preferred,  :boolean, :default => false
      t.column :im_type,    :string,  :default => ''
      t.column :im_address, :string,  :default => ''
    end
  end

  def self.down
    drop_table :account_im_addresses
  end
end
