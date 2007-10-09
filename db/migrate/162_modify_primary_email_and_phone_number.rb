=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)
class ModifyPrimaryEmailAndPhoneNumber < ActiveRecord::Migration
  def self.up
    rename_column :people, :primary_phone, :primary_phone_cache
    rename_column :people, :primary_email, :primary_email_cache
  end

  def self.down
    rename_column :people, :primary_phone_cache, :primary_phone
    rename_column :people, :primary_email_cache, :primary_email
  end
end
