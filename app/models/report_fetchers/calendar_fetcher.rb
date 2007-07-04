=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CalendarFetcher < ReportFetcher 
  class << self
    def default_title(report)
      report.reportable.name
    end                                              
    
    def summary(report)
      "Events for the next 7 days from a given calendar."
    end
       
    def html_url(report)
      {:controller => 'calendar', :action => 'list', :calendar_id => report.reportable.id}  
    end
                       
    def group_type(report)
      'calendar_report'  
    end                  
    
    def reportable_type
      Calendar
    end        
  end
end