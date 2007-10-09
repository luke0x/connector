=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class ContactsFetcher < ReportFetcher
  class << self
    def summary(report)
      "All of a user's contacts."  
    end
    
    def html_url(report)
      {:controller => 'people', :action => 'list', :group => report.reportable.contact_list.id}  
    end                
    
    def group_type(report)
      'people'  
    end              
  end
end