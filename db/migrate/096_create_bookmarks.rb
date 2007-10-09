=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CreateBookmarks < ActiveRecord::Migration
  def self.up
    create_table :bookmarks do |t|
      t.column :organization_id,    :integer
      t.column :user_id,            :integer
      t.column :bookmark_folder_id, :integer
      t.column :uri,                :text
      t.column :uri_sha1,           :text
      t.column :title,              :text
      t.column :notes,              :text
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    create_table :bookmark_folders do |t|
      t.column :user_id, :integer
    end
    User.find(:all).each do |user|
      user.create_bookmark_folder unless user.bookmark_folder
    end
  end

  def self.down
    drop_table :bookmarks
    drop_table :bookmark_folders
  end
end