=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class RecentCommentsFetcher < ReportFetcher 
  class << self  
    def summary(report)
      'Items that have recently been commented.'
    end                                        
    
    def html_url(report)
      {:controller => 'connect', :action => 'recent_comments', :id => report.reportable.id}
    end  
    
    def group_type(report)
      'comments'
    end
  end
end