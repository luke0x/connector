=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateCalendars < ActiveRecord::Migration
  def self.up
    create_table :calendars do |t|
      t.column :person_id,  :integer
      t.column :name,       :string,  :default => ''
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    add_column :events, :calendar_id, :integer
  end

  def self.down
    remove_column :events, :calendar_id
    drop_table :calendars
  end
end