=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class MessageCache < ActiveRecord::Migration
  def self.up
    add_column :messages, :has_attachments, :boolean
    add_column :messages, :sender, :text
    add_column :messages, :subject, :text
    add_column :messages, :date, :datetime
  end

  def self.down
    remove_column :messages, :has_attachments
    remove_column :messages, :sender
    remove_column :messages, :subject
    remove_column :messages, :date
  end
end
