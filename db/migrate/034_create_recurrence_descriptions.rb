=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateRecurrenceDescriptions < ActiveRecord::Migration
  def self.up
    create_table :recurrence_descriptions do |t|
      t.column :name, :string
      t.column :rule_text, :string
      t.column :seconds_to_increment, :integer
    end
  end

  def self.down
    drop_table :recurrence_descriptions
  end
end
