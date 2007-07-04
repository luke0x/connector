=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class CalendarAllFetcher < ReportFetcher
  class << self
    def default_title(report)
      "All Events"
    end

    def summary(report)
      "All of a user's events for the next 7 days."
    end

    def html_url(report)
      {:controller => 'calendar', :action => 'all_list'} 
    end                

    def group_type(report)                                                                                                   
      'calendar_report'
    end   
  end
end