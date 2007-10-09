=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateOrganizationOptions < ActiveRecord::Migration
  def self.up
    create_table :organization_options do |t|  
      t.column :organization_id, :integer
      t.column :key,             :string
      t.column :value,           :string
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
    end
  end

  def self.down
    drop_table :organization_options
  end
end