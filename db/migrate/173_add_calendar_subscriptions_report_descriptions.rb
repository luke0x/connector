=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class AddCalendarSubscriptionsReportDescriptions < ActiveRecord::Migration
  def self.up
    ReportDescription.create :name => 'calendar_subscription'
  end

  def self.down
    ReportDescription.find_by_name('calendar_subscription').destroy
  end
end
