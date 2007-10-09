=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class RootListFolders < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      unless root = user.list_folders.find(:first, :conditions => ["list_folders.name = 'Lists' AND list_folders.parent_id IS NULL"])
        root = user.list_folders.create(:name => 'Lists', :parent_id => nil)
      end

      user.list_folders.select{|lf| lf.parent_id.blank?}.each do |list_folder|
        next if list_folder == root
        list_folder.update_attribute(:parent_id, root.id)
      end
    end
  end

  def self.down
  end
end