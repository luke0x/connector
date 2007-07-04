=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateAccountSpecialDates < ActiveRecord::Migration
  def self.up
    create_table :account_special_dates do |t|
      t.column :person_id,    :integer
      t.column :preferred,    :boolean, :default => false
      t.column :description,  :text,    :default => ''
      t.column :special_date, :date
    end
  end

  def self.down
    drop_table :account_special_dates
  end
end
