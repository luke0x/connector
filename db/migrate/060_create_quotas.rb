=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateQuotas < ActiveRecord::Migration
  def self.up
    create_table :quotas do |t|
      t.column :organization_id, :integer
      t.column :gigabytes, :integer
      t.column :users, :integer
      t.column :custom_domains, :boolean
    end
  end

  def self.down
    drop_table :quotas
  end
end
