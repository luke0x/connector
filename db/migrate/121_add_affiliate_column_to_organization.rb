=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddAffiliateColumnToOrganization < ActiveRecord::Migration
  def self.up
    add_column :organizations, :affiliate_id, :integer, :default => 1
    Organization.update_all('affiliate_id = 1')
  end

  def self.down
    remove_column :organizations, :affiliate_id
  end
end
