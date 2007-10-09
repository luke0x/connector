=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class SearchSystem
  ITEM_CLASSES = [Message, Event, Person, JoyentFile, Bookmark, List]
  
  def self.search(needle)
    items = []
    ITEM_CLASSES.each do |klass|
      conditions = klass.search_fields.collect{|condition| "#{condition} LIKE ?"}
      conditions << "tags.name LIKE ?"
      include_parameters = [:owner, :tags]

      if klass == Message
        conditions_parameters = ["(#{conditions.join(' OR ')}) AND messages.active = TRUE AND mailboxes.full_name != 'INBOX.Trash'"] + ["%#{needle}%"] * conditions.length
        include_parameters << :mailbox
      else
        conditions_parameters = [conditions.join(' OR ')] + ["%#{needle}%"] * conditions.length
      end

      items.concat(klass.find(:all, :conditions => conditions_parameters, :include => include_parameters, :scope => :org_read))
    end
    items = items.sort_by(&:updated_at).reverse unless items.empty?
    items
  end
end