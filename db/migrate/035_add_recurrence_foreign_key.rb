=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddRecurrenceForeignKey < ActiveRecord::Migration
  def self.up
    add_column :events, :recurrence_description_id, :integer
    remove_column :events, :recur_rule    
  end

  def self.down
    remove_column :events, :recurrence_description_id
    add_column :events, :recur_rule, :text
  end
end
