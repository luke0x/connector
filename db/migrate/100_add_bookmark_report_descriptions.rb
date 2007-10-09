=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddBookmarkReportDescriptions < ActiveRecord::Migration
  def self.up
    ReportDescription.create :name => 'bookmarks_notifications'
    ReportDescription.create :name => 'bookmarks_all'    
    ReportDescription.create :name => 'bookmarks_everyone'
    ReportDescription.create :name => 'bookmarks_smart_group'
  end

  def self.down                                     
    ReportDescription.find_by_name('bookmarks_notifications').destroy
    ReportDescription.find_by_name('bookmarks_all').destroy
    ReportDescription.find_by_name('bookmarks_everyone').destroy
    ReportDescription.find_by_name('bookmarks_smart_group').destroy
  end
end
