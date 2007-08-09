# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is governed
# by either the GPLv2 or Joyent Commercial Software licenses.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$
module NotificationSystem
  class EmailNotifier
    def self.notify(notification)
      body =<<EOS
#{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize}).

#{MessageHelper.url_for(notification.item)}
EOS

      send_message :subject => "Connector Notification: #{notification.item.name}", 
                   :body    => body,
                   :to      => notification.notifiee.notifier_email.email_address,
                   :from    => JoyentConfig.email_notifier_from_address
    end
    
    def self.alarm(event)
      send_message :subject => "Connector Alarm: #{event.name}",
                   :body    => "#{event.start_time.strftime('%D %T')}\n#{event.name}\n#{event.location}",
                   :to      => event.owner.notifier_email.email_address,
                   :from    => JoyentConfig.email_notifier_from_address
    end
    
    def self.send_message(opts)
      host          = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user          = ENV['SMTP_USER'] || nil
      pass          = ENV['SMTP_PASS'] || nil
      auth          = ENV['SMTP_AUTH'] || nil

      tmail         = TMail::Mail.new
      tmail.to      = opts[:to]
      tmail.from    = opts[:from]
      tmail.subject = opts[:subject]
      tmail.body    = opts[:body]
      
      unless ENV['RAILS_ENV'] == 'test'
        Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
          smtp.send_message tmail.encoded, tmail.from, tmail.destinations
        end
      end
    end
  end
end
