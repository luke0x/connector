=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class RemoveRecurrenceDescriptionsTable < ActiveRecord::Migration
  def self.up
    drop_table :recurrence_descriptions
  end

  def self.down
    create_table "recurrence_descriptions", :force => true do |t|
      t.column "name",                 :string
      t.column "rule_text",            :string
      t.column "seconds_to_increment", :integer
      t.column "advance_arguments",    :string
    end
  end
end
