=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class LinkPeopleOrganization < ActiveRecord::Migration
  def self.up
    add_column :people, :organization_id, :integer
  end

  def self.down
    remove_column :people, :organization_id
  end
end
