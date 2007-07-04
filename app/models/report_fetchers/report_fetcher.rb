=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class ReportFetcher 
  class << self
    # Do not override this method, unless you want complete control of the title.
    # This is nice b/c it will prepend "First Last: <default_title>" when it is 
    # not a reportable which you own
    def title(report) 
      user   = reportable_type == User ? report.reportable : report.reportable.owner
      prefix = "#{user.full_name}'s " if user != report.owner 
      prefix.to_s + default_title(report)      
    end             
    
    def default_title(report)
      "#{name.sub(/fetcher/i, '').titlecase}"
    end
    
    # These are not currently being used...we could add them to 'title' on the group sidebar
    def summary(report)
      "Basic Report"
    end

    def html_url(report)
      {:controller => 'reports', :action => 'show', :id => report.id} 
    end                

    def js_url(report)
      html_url(report).merge({:dom_prefix => report.id})
    end              
       
    def group_type(report)                                                                                                   
      'report'
    end

    def reportable_type
      User
    end
  end
end