=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateTaggings < ActiveRecord::Migration
  def self.up
    create_table :taggings do |t|
      t.column :tag_id,        :integer
      t.column :tagger_id,     :integer
      t.column :taggable_id,   :integer
      t.column :taggable_type, :string
    end
  end

  def self.down
    drop_table :taggings
  end
end
