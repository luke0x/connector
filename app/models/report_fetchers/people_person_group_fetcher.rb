=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id: contacts_fetcher.rb 446 2007-10-09 16:53:28Z chris@joyent.com $
--
=end #(end)

class PeoplePersonGroupFetcher < ReportFetcher
  class << self
    
    def default_title(report)
      report.reportable.name
    end  
    
    def summary(report)
      "Contacts belonging to a person group."  
    end
    
    def html_url(report)
      {:controller => 'people', :action => 'list', :group => report.reportable.url_id}  
    end          
    
    def group_type(report)
      'person_group'  
    end      
    
    def reportable_type
      PersonGroup  
    end    
  end
end
