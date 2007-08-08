module NotificationSystem
  class MessageHelper
    def self.url_for(item)
      case item
      when Message
        "http://#{item.organization.system_domain.web_domain}/mail/#{item.mailbox_id}/#{item.id}"
      when Event, StubEvent
        if calendar = item.calendars.select{|cal| cal && (User.current.id == cal.user_id)}.first
          "http://#{item.organization.system_domain.web_domain}/calendar/#{item.calendar_id}/#{item.id}"
        else
          "http://#{item.organization.system_domain.web_domain}/calendar/#{item.calendars.first.id}/#{item.id}"
        end
      when Person
        "http://#{item.organization.system_domain.web_domain}/person/#{item.id}"
      when JoyentFile
        "http://#{item.organization.system_domain.web_domain}/files/#{item.folder_id}/#{itemid}"
      when Bookmark
        "http://#{item.organization.system_domain.web_domain}/bookmarks/#{item.id}/show"
      when List
        "http://#{item.organization.system_domain.web_domain}/lists/#{item.id}"
      else
        ''
      end
    end
    
    def self.notification_time(notification)
      time = User.current.person.tz.utc_to_local(notification.created_at)
      time.strftime('%I:%M%p on %m/%d/%Y').gsub(/ 0(\d)/, ' \1').gsub(/^0(\d)/, '\1').downcase
    end
  end
end
