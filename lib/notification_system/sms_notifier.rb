# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is governed
# by either the GPLv2 or Joyent Commercial Software licenses.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$
module NotificationSystem
  class SmsNotifier
    def self.notify(notification)
      host          = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user          = ENV['SMTP_USER'] || nil
      pass          = ENV['SMTP_PASS'] || nil
      auth          = ENV['SMTP_AUTH'] || nil
    
      tmail         = TMail::Mail.new
      tmail.from    = notification.notifier.system_email
      tmail.body    = "#{MessageHelper.url_for(notification.item)} #{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize})."
      tmail.subject = "Notification: #{notification.item.name}"

      unless ENV['RAILS_ENV'] == 'test' or recipients(notification).empty?
        recipients(notification).each do |sms_recipient|
          tmail.to = sms_recipient.sms_address
          Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
            smtp.send_message tmail.encoded, tmail.from, tmail.destinations
          end
        end
      end
    end
    
    def self.recipients(notification)
      notification.notifiee.person.phone_numbers.select{|ph| ph.use_notifier? && ph.confirmed?}
    end
    
  end
end