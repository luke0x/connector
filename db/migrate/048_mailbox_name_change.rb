=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailboxNameChange < ActiveRecord::Migration
  def self.up
    add_column    :mailboxes, :full_name, :string
    remove_column :mailboxes, :name
  end

  def self.down
    add_column    :mailboxes, :name, :string
    remove_column :mailboxes, :full_name
  end
end
