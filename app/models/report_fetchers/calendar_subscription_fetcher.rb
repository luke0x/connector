=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class CalendarSubscriptionFetcher < ReportFetcher 
  class << self
    def default_title(report)
      report.reportable.name
    end                                              
    
    def summary(report)
      "Events for the next 7 days from a given calendar."
    end
       
    def html_url(report)
      {:controller => 'calendar_subscriptions', :action => 'list', :calendar_subscription_id => report.reportable.id}  
    end
                       
    def group_type(report)
      'ics_subscription'  
    end                  
    
    def reportable_type
      CalendarSubscription
    end        
  end
end