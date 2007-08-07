module NotificationSystem
  class EmailNotifier
    def self.notify(notifaction)
      host          = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user          = ENV['SMTP_USER'] || nil
      pass          = ENV['SMTP_PASS'] || nil
      auth          = ENV['SMTP_AUTH'] || nil

      tmail         = TMail::Mail.new
      tmail.body    = "You are being notified of #{notification.name} (#{notification.item.class_humanize}) by #{notification.notifier.full_name}."
      tmail.to      = notification.notifiee.system_email
      tmail.subject = "Connector Notification: #{notification.name}"

      unless ENV['RAILS_ENV'] == 'test'
        Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
          smtp.send_message tmail.encoded, tmail.from, tmail.destinations
        end
      end
    end
  end
end
