=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class SearchObserver < ActiveRecord::Observer
  observe Person, JoyentFile, Event
  
  cattr_accessor :enabled
  @@enabled = true 
        
  def after_save(item)
    if SearchObserver.enabled
      item.add_to_search_index
    end
  end
  
  def after_destroy(item)
    if SearchObserver.enabled
      Searchable.search_system.remove_item(item)
    end
  end
end