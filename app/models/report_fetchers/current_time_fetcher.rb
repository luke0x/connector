=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CurrentTimeFetcher < ReportFetcher 
  class << self         
    def summary(report)
      "Current time for each user in the organization."  
    end     
    
    def group_type(report)
    	"currentTime"
    end
    
    def html_url(report)
      {:controller => 'people', :action => 'current_time', :id => report.reportable.id}
    end                 
  end
end