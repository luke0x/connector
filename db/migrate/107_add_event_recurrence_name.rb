=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddEventRecurrenceName < ActiveRecord::Migration
  def self.up
    add_column "events", "recurrence_name", :string
    Event.find(:all).each do |event|
      ActiveRecord::Base.connection.execute("update events set recurrence_name = '#{event.recurrence_description ? event.recurrence_description.name : ''}' where id = #{event.id}")
    end
  end

  def self.down
    remove_column "events", "recurrence_name"
  end
end