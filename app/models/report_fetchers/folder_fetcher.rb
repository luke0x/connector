=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class FolderFetcher < ReportFetcher 
  class << self
    def default_title(report)
      report.reportable.name
    end                     
    
    def summary(report)
      "Files appearing in the given folder."
    end      
       
    def html_url(report)
      {:controller => 'files', :action => 'list', :folder_id => report.reportable.id}  
    end
                            
    def group_type(report)
      'files_report'
    end
    
    def reportable_type
      Folder  
    end       
  end
end