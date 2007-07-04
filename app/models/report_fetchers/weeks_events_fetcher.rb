=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class WeeksEventsFetcher < ReportFetcher 
  class << self 
    def default_title(report)
      "This Week's Events"
    end
            
    def summary(report)
      "Events for the next 7 days for a given user."  
    end       
    
    def group_type(report)
    	"eventsReport"
    end         
    
    def html_url(report)
      {:controller => 'calendar', :action => 'weeks_events', :id => report.reportable.id}
    end                 
  end
end