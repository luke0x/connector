=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ContactListAssociations < ActiveRecord::Migration
  def self.up
    add_column :people, :contact_list_id, :integer
  end

  def self.down
    remove_column :people, :contact_list_id
  end
end
