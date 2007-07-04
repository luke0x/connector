=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class MessageFlagFix < ActiveRecord::Migration
  def self.up
    add_column "messages", "draft", :boolean, :default => false
    add_column "messages", "answered", :boolean, :default => false
    add_column "messages", "forwarded", :boolean, :default => false
    
    remove_column :messages, :flags
  end

  def self.down
    remove_column "messages", "draft"
    remove_column "messages", "answered"
    remove_column "messages", "forwarded"
    
    add_column :messages, :flags, :text
  end
end
