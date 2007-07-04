=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CleanUpMissingUsersData < ActiveRecord::Migration
  def self.up
    # orphaned user db rows
    puts "Destroying orphaned user db rows..."
    user_ids = User.find(:all).collect(&:id)
    [LoginToken, Comment, Invitation, Permission, SmartGroup, Message, Mailbox, Event, Calendar, Person, ContactList, JoyentFile, Folder].each do |c|
      items = c.find(:all, :conditions => [ "user_id NOT IN (?)", user_ids ])
      items.each do |i|
        puts "Destroying: #{i.class}: #{i.id}"
        i.destroy
      end
    end
    items = Tagging.find(:all, :conditions => [ "tagger_id NOT IN (?)", user_ids ])
    items.each do |i|
      puts "Destroying: #{i.class}: #{i.id}"
      i.destroy
    end

    # orphaned org db rows
    puts "Destroying orphaned org db rows..."
    org_ids = Organization.find(:all).collect(&:id)
    [Domain, User, Tag, Notification, Quota, Message, Event, Person, JoyentFile].each do |c|
      items = c.find(:all, :conditions => [ "organization_id NOT IN (?)", org_ids ])
      items.each do |i|
        puts "Destroying: #{i.class}: #{i.id}"
        i.destroy
      end
    end
    
    # directories + files
    disk_org_ids = []
    Dir.entries(Organization.storage_root).each do |d|
      disk_org_ids << d.to_i
    end
    disk_org_ids.reject!{|o| o == 0}
    disk_org_ids.each do |o|
      disk_usernames = []
      Dir.entries("#{Organization.storage_root}/#{o}/users").each do |d|
        disk_usernames << d
      end
      disk_usernames.reject!{|u| ['.', '..', '.svn'].include?(u)}
      puts "Deleting orphaned user dirs (org #{o})..."
      disk_usernames.each do |u|
        unless User.find(:first, :conditions => [ "username = ? AND organization_id = ?", u, o ])
          puts "rm -rf'ing: " + File.expand_path("#{Organization.storage_root}/#{o}/users/#{u}")
          FileUtils.rm_rf File.expand_path("#{Organization.storage_root}/#{o}/users/#{u}")
        end
      end

      disk_icons = []
      Dir.entries("#{Organization.storage_root}/#{o}/icons").each do |d|
        unless ['.', '..', '.svn'].include?(d)
          disk_icons << d
        end
      end
      puts "Deleting orphaned people icons (org #{o})..."
      disk_icons.each do |i|
        person_id = File.basename(i, File.extname(i))
        unless Person.find(:first, :conditions => [ "id = ? AND organization_id = ?", person_id, o ])
          puts "rm -f'ing: " + File.expand_path("#{Organization.storage_root}/#{o}/icons/#{i}")
          FileUtils.rm_f File.expand_path("#{Organization.storage_root}/#{o}/icons/#{i}")
        end
      end
    end

    puts "Deleting orphaned org dirs..."
    disk_org_ids.each do |o|
      unless Organization.find(:first, :conditions => [ "id = ?", o ])
        puts "rm -rf'ing: " + File.expand_path("#{Organization.storage_root}/#{o}")
        FileUtils.rm_rf File.expand_path("#{Organization.storage_root}/#{o}")
      end
    end    
  end

  def self.down
  end
end