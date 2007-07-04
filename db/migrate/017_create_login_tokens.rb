=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateLoginTokens < ActiveRecord::Migration
  def self.up
    create_table :login_tokens do |t|
       t.column :value, :string
       t.column :user_id, :integer
       t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :login_tokens
  end
end
