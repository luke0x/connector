=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class AddReportDescriptions < ActiveRecord::Migration
  def self.up
    ReportDescription.create :name => 'connect_notifications' 
    ReportDescription.create :name => 'mail_notifications'    
    ReportDescription.create :name => 'files_notifications'   
    ReportDescription.create :name => 'calendar_notifications'
    ReportDescription.create :name => 'people_notifications'  
    ReportDescription.create :name => 'connect_smart_group'
    ReportDescription.create :name => 'mail_smart_group'
    ReportDescription.create :name => 'files_smart_group'
    ReportDescription.create :name => 'calendar_smart_group'
    ReportDescription.create :name => 'people_smart_group'
    ReportDescription.create :name => 'mailbox'
    ReportDescription.create :name => 'folder'
    ReportDescription.create :name => 'calendar'
    ReportDescription.create :name => 'calendar_all'
    ReportDescription.create :name => 'users'
    ReportDescription.create :name => 'contacts'
    ReportDescription.create :name => 'current_time'    
    ReportDescription.create :name => 'unread_messages'
    ReportDescription.create :name => 'recent_comments'
    ReportDescription.create :name => 'todays_events'
    ReportDescription.create :name => 'weeks_events'                                                                            
  end

  def self.down
    ReportDescription.find(:all).each{|rd| rd.destroy}
  end
end
