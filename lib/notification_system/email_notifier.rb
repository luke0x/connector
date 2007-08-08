module NotificationSystem
  class EmailNotifier
    def self.notify(notification)
      host          = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user          = ENV['SMTP_USER'] || nil
      pass          = ENV['SMTP_PASS'] || nil
      auth          = ENV['SMTP_AUTH'] || nil

      body =<<EOS
#{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize}).

#{ItemUrlHelper.url_for(notification.item)}
EOS

      tmail         = TMail::Mail.new
      tmail.to      = notification.notifiee.system_email # TODO needs to change to stored preference, which isn't done yet
      tmail.from    = notification.notifier.system_email
      tmail.subject = "Connector Notification: #{notification.item.name}"
      tmail.body    = body

      unless ENV['RAILS_ENV'] == 'test'
        Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
          smtp.send_message tmail.encoded, tmail.from, tmail.destinations
        end
      end
    end
  end
end
