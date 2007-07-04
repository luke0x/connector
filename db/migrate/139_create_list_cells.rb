=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateListCells < ActiveRecord::Migration
  def self.up
    create_table :list_cells do |t|
      t.column :list_column_id, :integer
      t.column :list_row_id, :integer
      t.column :value, :string
    end
  end

  def self.down
    drop_table :list_cells
  end
end