=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ListsStandardGroupFetcher < ReportFetcher 
  class << self
    def default_title(report)
      report.reportable.name
    end                     
    
    def summary(report)
      "Lists appearing in the given list folder."
    end      
       
    def html_url(report)
      {:controller => 'lists', :action => 'index', :group => report.reportable.id}  
    end

    def js_url(report)
      {:controller => 'lists', :action => 'index', :group => report.reportable.id, :dom_prefix => report.id}
    end

    def group_type(report)
      'lists_report'
    end
    
    def reportable_type
      ListFolder
    end       
  end
end