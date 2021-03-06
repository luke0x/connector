=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MailboxFetcher < ReportFetcher 
  class << self
    def default_title(report)
      (report.reportable.name == 'INBOX') ? 'Inbox' : report.reportable.name
    end    
                            
    def summary(report)
      "Messages appearing in the given mailbox."  
    end                                        
    
    def html_url(report)
      {:controller => 'mail', :action => 'list', :id => report.reportable.id}  
    end
    
    def group_type(report)
    	"unreadMessages"
    end
    
    def reportable_type
      Mailbox  
    end        
  end
end