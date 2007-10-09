=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddListsReportDescriptions < ActiveRecord::Migration
  def self.up
    ReportDescription.create :name => 'lists_standard_group'
    ReportDescription.create :name => 'lists_smart_group'
    ReportDescription.create :name => 'lists_notifications'
  end

  def self.down                                     
    ReportDescription.find_by_name('lists_standard_group').destroy
    ReportDescription.find_by_name('lists_smart_group').destroy
    ReportDescription.find_by_name('lists_notifications').destroy
  end
end