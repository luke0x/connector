module NotificationSystem
  class EmailNotificationSystem    
    def self.notify(notifaction)
      host     = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user     = ENV['SMTP_USER'] || nil
      pass     = ENV['SMTP_PASS'] || nil
      auth     = ENV['SMTP_AUTH'] || nil

      tmail         = TMail::Mail.new
      tmail.body    = notification.message
      tmail.to      = 1 # notification address
      tmail.subject = 'Connector Notification'

      unless ENV['RAILS_ENV'] == 'test'
        Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
          smtp.send_message tmail.encoded, tmail.from, tmail.destinations
        end
      end
    end
  end
end
