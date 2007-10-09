=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddUpdatedAtToLoginToken < ActiveRecord::Migration
  def self.up
    add_column :login_tokens, :updated_at, :datetime
  end

  def self.down
    remove_column :login_tokens, :updated_at
  end
end