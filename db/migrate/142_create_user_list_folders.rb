=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CreateUserListFolders < ActiveRecord::Migration
  def self.up
    add_column :list_folders, :organization_id, :integer

    Organization.find(:all).each do |organization|
      organization.users_and_admins.each do |user|
        if user.list_folders.select{|lf| lf.parent_id == nil}.blank?
          user.list_folders.create(:name => 'Lists', :parent_id => nil, :organization_id => user.organization_id)
        end
      end
    end
  end

  def self.down
    remove_column :list_folders, :organization_id
  end
end