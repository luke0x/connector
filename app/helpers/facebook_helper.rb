=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module FacebookHelper
  def facebook_app_landing(app)
    facebook_url("home/#{app}")
  end
  
  def facebook_url_for(item)
    case item
    when Message
      facebook_url("mail/#{item.mailbox_id}/#{item.id}")
    when Event, StubEvent
      if calendar = item.calendars.select{|cal| cal && (User.current.id == cal.user_id)}.first
        facebook_url("calendar/#{calendar.id}/#{item.id}")
      else
        facebook_url("calendar/#{item.primary_calendar.id}/#{item.id}")
      end
    when Person
      facebook_url("person/#{item.id}")
    when JoyentFile
      facebook_url("files/#{item.folder_id}/#{item.id}")
    when Bookmark
      facebook_url("bookmarks/#{item.id}/show")
    when List
      facebook_url("lists/#{item.id}")
    else
      ''
    end
  end  
  
  def facebook_image_url(image_path)
    facebook_url("images/#{image_path}")
  end
  
  def facebook_url(relative_path)
    "http://63.193.186.12/#{relative_path}"    
    # "http://#{current_organization.primary_domain.web_domain}/#{relative_path}"    
  end
end
