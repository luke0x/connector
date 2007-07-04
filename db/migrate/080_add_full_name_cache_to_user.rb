=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddFullNameCacheToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :full_name, :string
    print User.find(:all).collect do |user|
      user.full_name= user.person.full_name
      user.save
    end
  end

  def self.down
    remove_column :users, :full_name
  end
end
