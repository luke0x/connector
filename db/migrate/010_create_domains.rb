=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateDomains < ActiveRecord::Migration
  def self.up
    create_table :domains do |t|
      t.column :organization_id, :integer
      t.column :web_domain,      :string
      t.column :email_domain,    :string
      t.column :primary,         :boolean
    end
  end

  def self.down
    drop_table :domains
  end
end
