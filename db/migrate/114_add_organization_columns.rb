=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddOrganizationColumns < ActiveRecord::Migration
  def self.up
    [:mailboxes, :calendars, :contact_lists, :folders, :bookmark_folders, :smart_groups].each do |sym|
      add_column sym, :organization_id, :integer
    end
    [Mailbox, Calendar, ContactList, Folder, BookmarkFolder, SmartGroup].each do |klass|
      klass.find(:all).each{|c| c.update_attributes(:organization_id => c.owner.organization.id)}
    end
  end

  def self.down
    [:mailboxes, :calendars, :contact_lists, :folders, :bookmark_folders, :smart_groups].each do |sym|
      remove_column sym, :organization_id
    end
  end
end