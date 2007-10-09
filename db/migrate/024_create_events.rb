=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :organization_id, :integer
      t.column :person_id,       :integer
      t.column :name,            :string
      t.column :location,        :text
      t.column :recur_rule,      :text
      t.column :start_time,      :datetime
      t.column :duration,        :integer
      t.column :recur_end_time,  :datetime
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
    end
  end

  def self.down
    drop_table :events
  end
end
