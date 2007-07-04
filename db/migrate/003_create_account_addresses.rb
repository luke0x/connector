=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateAccountAddresses < ActiveRecord::Migration
  def self.up
    create_table :account_addresses do |t|
      t.column :person_id,    :integer
      t.column :preferred,    :boolean
      t.column :address_type, :string, :default => ''
      t.column :street,       :string, :default => ''
      t.column :city,         :string, :default => ''
      t.column :state,        :string, :default => ''
      t.column :postal_code,  :string, :default => ''
      t.column :geocode,      :string, :default => ''
      t.column :country_name, :string, :default => ''
    end
  end

  def self.down
    drop_table :account_addresses
  end
end
