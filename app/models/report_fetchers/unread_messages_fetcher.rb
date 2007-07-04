=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class UnreadMessagesFetcher < ReportFetcher
  class << self
    def summary(report)
      'Unread messages from the Inbox for a given user.'  
    end                
    
    def group_type(report)
    	"unreadMessages"
    end      
    
    def html_url(report)
      {:controller => 'mail', :action => 'unread_messages', :id => report.reportable.inbox}
    end
  end
end