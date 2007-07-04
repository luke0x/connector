=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class NoPathnameUseFilename < ActiveRecord::Migration
  def self.up
    add_column :joyent_files, :filename, :string
    remove_column :joyent_files, :pathname
  end

  def self.down
    add_column :joyent_files, :pathname, :string
    remove_column :joyent_files, :filename
  end
end
