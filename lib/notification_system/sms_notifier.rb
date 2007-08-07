module NotificationSystem
  class SmsNotifier
    cattr_accessor :host, :port, :username, :password, :authorization
    @@host           = 'localhost'
    @@port           = 25
    @@username       = 'username'
    @@password       = 'password'
    @@authorization  = nil
    @@from_recipient = 'user@email.com'
    
    def notify(users, joyent_item)
      tmail         = TMail::Mail.new
      tmail.body    = message
      tmail.to      = recipients
      tmail.subject = 'Connector Notification'

      Net::SMTP.start(@@host, @@port, @@host, @@username, @@password, @@authorization) do |smtp|        
        smtp.send_message message, tmail.encoded, tmail.from, tmail.destinations
      end
    end  
  end
end