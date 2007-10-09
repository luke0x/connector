=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class BookmarksEveryoneFetcher < ReportFetcher
  class << self
    def default_title(report)
      "Others' Bookmarks"
    end

    def summary(report)
      "Everyone else's bookmarks you have access to view."
    end

    def html_url(report)
      {:controller => 'bookmarks', :action => 'list_everyone'} 
    end                

    def group_type(report)                                                                                                   
      'bookmarks_report'
    end   
  end
end