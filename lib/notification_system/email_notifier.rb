module NotificationSystem
  class EmailNotificationSystem    
    def self.notify(notifaction)
      host     = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user     = ENV['SMTP_USER'] || nil
      pass     = ENV['SMTP_PASS'] || nil
      auth     = ENV['SMTP_AUTH'] || nil

      tmail         = TMail::Mail.new
      tmail.body    = message
      tmail.to      = 1 # notification address
      tmail.subject = 'Connector Notification'

      unless ENV['RAILS_ENV'] == 'test'
        Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
          smtp.send_message @mail.encoded, @mail.from, @mail.destinations
        end
      end
      
    end
  end
end
