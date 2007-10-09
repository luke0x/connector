=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RenameAccountTables < ActiveRecord::Migration
  def self.up
    rename_table :account_addresses,       :addresses
    rename_table :account_email_addresses, :email_addresses
    rename_table :account_im_addresses,    :im_addresses
    rename_table :account_phone_numbers,   :phone_numbers
    rename_table :account_special_dates,   :special_dates
    rename_table :account_websites,        :websites
  end

  def self.down
    rename_table :addresses,       :account_addresses
    rename_table :email_addresses, :account_email_addresses
    rename_table :im_addresses,    :account_im_addresses
    rename_table :phone_numbers,   :account_phone_numbers
    rename_table :special_dates,   :account_special_dates
    rename_table :websites,        :account_websites
  end
end
