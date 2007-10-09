=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class BookmarksAllFetcher < ReportFetcher
  class << self
    def default_title(report)
      "Bookmarks"
    end

    def summary(report)
      "All of a user's bookmarks."
    end

    def html_url(report)
      {:controller => 'bookmarks', :action => 'list', :bookmark_folder_id => report.reportable.bookmark_folder.id} 
    end                

    def group_type(report)                                                                                                   
      'bookmarks_report'
    end   
  end
end