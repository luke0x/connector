=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CleanUpOrphanedGuestUsers < ActiveRecord::Migration
  def self.up
    User.find(:all, :conditions => ["guest = ?", true]).each do |guest|
      guest.destroy if guest.person.blank?
    end
  end

  def self.down
    # n/a
  end
end