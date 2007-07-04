=begin #(fold)
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is governed
by either the GPLv2 or Joyent Commercial Software licenses.

Report issues and contribute at http://dev.joyent.com/

$Id$
=end #(end)

class TestSearchSystem
  def initialize
    reset
  end
  
  def reset
    @docs = []
    @outdocs = []
  end
  
  attr_reader :docs, :outdocs
  
  def add_item(doc)
    @docs << doc
  end
  
  def smart_group(sg, limit=nil, offset=nil)
    res = sg.tags.index("foo") rescue false
    if res
      items = text_query("foo", sg.smart_group_description.item_type)
      items = items[offset..-1] || [] if offset
      items = items[0..(limit - 1)] || [] if limit
      items
    else
      []
    end
  end
  
  def text_query(q, type=nil)
    if q == "foo"
      case type
      when "Message"    then User.current.messages.find(:all)
      when "Event"      then User.current.calendars.collect{|c| c.events}.flatten
      when "Person"     then User.current.contact_list.people.find(:all)
      when "JoyentFile" then User.current.joyent_files.find(:all)   
      when "Bookmark"   then User.current.bookmarks.find(:all)   
      when nil
         User.current.messages.find(:all) +
         User.current.calendars.collect{|c| c.events}.flatten +
         User.current.contact_list.people.find(:all) +
         User.current.joyent_files.find(:all) +
         User.current.bookmarks.find(:all)   
      else
        []
      end
    else
      return []
    end
  end
  
  def remove_item(i)
    @outdocs << i
  end
  
end
