=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class TodaysEventsFetcher < ReportFetcher 
  class << self 
    def default_title(report)
      "Today's Events"
    end
            
    def summary(report)
      "Events for today for a given user."  
    end     
    
    def group_type(report)
    	"eventsReport"
    end                  
    
    def html_url(report)
      {:controller => 'calendar', :action => 'todays_events', :id => report.reportable.id}
    end                 
  end
end