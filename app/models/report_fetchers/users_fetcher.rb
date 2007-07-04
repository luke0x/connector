=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class UsersFetcher < ReportFetcher
  class << self  
    def summary(report)
      "All of the users in the organization."  
    end
    
    def html_url(report)
      {:controller => 'people', :action => 'list', :group => 'users'}  
    end                
    
    def group_type(report)
      'people'  
    end                                                       
  end
end