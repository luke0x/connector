=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :affiliates, :name
    add_index :bookmark_folders, :organization_id
    add_index :calendars, :organization_id
    add_index :contact_lists, :organization_id
    add_index :folders, :organization_id
    add_index :guest_paths, :user_id
    add_index :guest_paths, :guest_id
    add_index :login_tokens, :user_id
    add_index :mailboxes, :organization_id
    add_index :organizations, :affiliate_id
    add_index :smart_groups, :organization_id
    add_index :subscriptions, :subscribable_id
    add_index :subscriptions, :subscribable_type
    add_index :subscriptions, :user_id
    add_index :users, :identity_id
  end

  def self.down
    remove_index :affiliates, :name
    remove_index :bookmark_folders, :organization_id
    remove_index :calendars, :organization_id
    remove_index :contact_lists, :organization_id
    remove_index :folders, :organization_id
    remove_index :guest_paths, :user_id
    remove_index :guest_paths, :guest_id
    remove_index :login_tokens, :user_id
    remove_index :mailboxes, :organization_id
    remove_index :organizations, :affiliate_id
    remove_index :smart_groups, :organization_id
    remove_index :subscriptions, :subscribable_id
    remove_index :subscriptions, :subscribable_type
    remove_index :subscriptions, :user_id
    remove_index :users, :identity_id
  end
end