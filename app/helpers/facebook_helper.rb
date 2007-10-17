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
  def facebook_app_landing(user, app)
    "http://#{user.organization.primary_domain.web_domain}/home/#{app}"
  end
  
  def facebook_url_for(item)
    case item
    when Message
      "http://#{item.organization.primary_domain.web_domain}/mail/#{item.mailbox_id}/#{item.id}"
    when Event, StubEvent
      if calendar = item.calendars.select{|cal| cal && (User.current.id == cal.user_id)}.first
        "http://#{item.organization.primary_domain.web_domain}/calendar/#{calendar.id}/#{item.id}"
      else
        "http://#{item.organization.primary_domain.web_domain}/calendar/#{item.primary_calendar.id}/#{item.id}"
      end
    when Person
      "http://#{item.organization.primary_domain.web_domain}/person/#{item.id}"
    when JoyentFile
      "http://#{item.organization.primary_domain.web_domain}/files/#{item.folder_id}/#{item.id}"
    when Bookmark
      "http://#{item.organization.primary_domain.web_domain}/bookmarks/#{item.id}/show"
    when List
      "http://#{item.organization.primary_domain.web_domain}/lists/#{item.id}"
    else
      ''
    end
  end  
  
  def facebook_image_url(user, image_path)
    "http://#{user.organization.primary_domain.web_domain}/images/facebook/#{image_path}"
  end
end
