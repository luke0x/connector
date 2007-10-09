=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailFilenameField < ActiveRecord::Migration
  def self.up
    add_column :messages, :filename, :string
    remove_column :messages, :uid
    add_index "messages", ["filename"], :name => "index_messages_on_filename"
  end

  def self.down
    remove_column :messages, :filename
    add_column :messages, :uid,             :integer
  end
end
