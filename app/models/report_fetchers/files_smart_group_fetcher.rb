=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class FilesSmartGroupFetcher < ReportFetcher 
  class << self   
    def default_title(report)
      report.reportable.name
    end           
    
    def summary(report)
      "Files in a smart group from the Files application."
    end             
    
    def html_url(report)
      {:controller => 'files', :action => 'smart_list', :smart_group_id => "s#{report.reportable.id}"}          
    end
    
    def group_type(report)
      'smart_group'  
    end
       
    def reportable_type
      SmartGroup  
    end
  end
end