=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateAccountPhoneNumbers < ActiveRecord::Migration
  def self.up
    create_table :account_phone_numbers do |t|
      t.column :person_id,         :integer
      t.column :preferred,         :boolean, :default => false
      t.column :phone_number_type, :string,  :default => ''
      t.column :phone_number,      :string,  :default => ''
    end
  end

  def self.down
    drop_table :account_phone_numbers
  end
end
