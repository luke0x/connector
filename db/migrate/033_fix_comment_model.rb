=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class FixCommentModel < ActiveRecord::Migration
  def self.up
    drop_table :commentings
    
    add_column :comments, :commentable_id,   :integer
    add_column :comments, :commentable_type, :string
  end

  def self.down
    create_table :commentings do |t|
      t.column :comment_id, :integer
      t.column :commentable_id, :integer
      t.column :commentable_type, :string
    end
    
    remove_column :comments, :commentable_id
    remove_column :comments, :commentable_type
  end
end
