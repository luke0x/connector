=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module NotificationSystem
  class FacebookNotifier
    cattr_accessor :facebook_system
    @@facebook_system = User.facebook_system
    
    def self.notify(notification)
      options         = {}
      options[:to]    = notification.notifiee
      options[:title] = "#{notification.notifier.full_name} notified you of the #{notification.item.class_humanize} \"<a href=\"#{MessageHelper.url_for(notification.item)}\">#{notification.item.name}</a>\""

      send_message(options)
    end
       
    def self.alarm(event, user)
      options         = {}
      options[:to]    = user
      options[:title] = "Alarm: <a href=\"#{MessageHelper.url_for(event)}\">#{event.name}</a> at #{event.alarm_time_in_user_tz.strftime('%D %I:%M %p')} (#{event.location})"

      send_message(options)
    end
    
    private

    def self.send_message(options)
      facebook_system.add_news_item(options[:title], options[:body], options[:to])
    end
  end
end