=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class OwnershipOnUsers < ActiveRecord::Migration
  def self.up
    rename_column :calendars,    :person_id, :user_id
    rename_column :comments,     :person_id, :user_id
    rename_column :events,       :person_id, :user_id
    rename_column :folders,      :person_id, :user_id
    rename_column :invitees,     :person_id, :user_id
    rename_column :joyent_files, :person_id, :user_id
    rename_column :notices,      :person_id, :user_id
    rename_column :permissions,  :person_id, :user_id
  end

  def self.down
    rename_column :calendars,    :user_id, :person_id
    rename_column :comments,     :user_id, :person_id
    rename_column :events,       :user_id, :person_id
    rename_column :folders,      :user_id, :person_id
    rename_column :invitees,     :user_id, :person_id
    rename_column :joyent_files, :user_id, :person_id
    rename_column :notices,      :user_id, :person_id
    rename_column :permissions,  :user_id, :person_id
  end
end
