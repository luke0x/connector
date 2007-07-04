=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class GiveCommentsTimes < ActiveRecord::Migration
  def self.up
    add_column :comments, :created_at, :datetime
    add_column :comments, :updated_at, :datetime
    Comment.find(:all).each do |c|
      c.created_at = Time.now
      c.updated_at = c.created_at
      c.save
    end
  end

  def self.down
    remove_column :comments, :created_at
    remove_column :comments, :updated_at
  end
end