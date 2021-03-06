=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# Not sure how this is going to be implemented
class FilesServiceFetcher < ReportFetcher
  class << self 
    def summary(report)
      "All of the user's service files."
    end
    
    def html_url(report)  
      {:controller => 'files', :action => 'service'}
    end                 
    
    def group_type(report)
      'service'
    end                         
  end  
end