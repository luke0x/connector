=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateAccountEmailAddresses < ActiveRecord::Migration
  def self.up
    create_table :account_email_addresses do |t|
      t.column :person_id,     :integer
      t.column :preferred,     :boolean, :default => false
      t.column :email_type,    :string,  :default => ''
      t.column :email_address, :string,  :default => ''
    end
  end

  def self.down
    drop_table :account_email_addresses
  end
end
