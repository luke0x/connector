module NotificationSystem
  class SmsNotifier
    def self.notify(notification)
      notifiable = notification.notifiee.person.phone_numbers.find_by_confirmed(true)
      
      host          = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
      user          = ENV['SMTP_USER'] || nil
      pass          = ENV['SMTP_PASS'] || nil
      auth          = ENV['SMTP_AUTH'] || nil
      
      body =<<EOS
#{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize}).

#{MessageHelper.url_for(notification.item)}
EOS

      tmail         = TMail::Mail.new
      tmail.from    = notification.notifier.system_email
      tmail.body    = body
      tmail.to      = notifiable.sms_address
      tmail.subject = "Notification: #{notification.item.name}"

      unless ENV['RAILS_ENV'] == 'test' or notifiable.blank?
        Net::SMTP.start(host, 25, host, user, pass, auth) do |smtp|
          smtp.send_message tmail.encoded, tmail.from, tmail.destinations
        end
      end
    end
  end
end