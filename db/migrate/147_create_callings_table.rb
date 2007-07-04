=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateCallingsTable < ActiveRecord::Migration
  def self.up
    create_table :callings do |t|
      t.column :call_id,      :integer
      t.column :callee_id,    :integer
      t.column :phone_number, :string
    end
  end

  def self.down
    drop_table :callings
  end
end
