=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MessageObserver < ActiveRecord::Observer
  # def after_create(message)
  #   Searchable.search_system.add_item(message)
  # end

  #def after_update(message)
    #Searchable.search_system.remove_item(message)
    #Searchable.search_system.add_item(message)
  #end

  #def after_destroy(message)
    #Searchable.search_system.remove_item(message)
  #end
end
