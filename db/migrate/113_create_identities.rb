=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateIdentities < ActiveRecord::Migration
  def self.up
    create_table(:identities) do |t|
      t.column :name, :string, :default => ''
    end
    add_column :users, :identity_id, :integer

    User.find(:all).each do |user|
      i = Identity.create
      user.identity_id = i.id
      user.save!
    end
  end

  def self.down
    remove_column :users, :identity_id
    drop_table :identities
  end
end
