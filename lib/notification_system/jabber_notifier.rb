require 'xmpp4r/client'

module NotificationSystem
  class JabberNotifier
    cattr_accessor :sender_account, :sender_password
    @@sender_account    = JoyentConfig.jabber_notifier_sender
    @@sender_password   = JoyentConfig.jabber_notifier_password

    @@received_file_log = Logger.new("#{RAILS_ROOT}/log/received_jabbers.log")
    @@client            = nil
    @@counter           = Time.now.to_i
    
    def self.notify(notification)
      options              = {}
      options[:subject]    = "Connector Notification"
      options[:plain_body] = "#{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize}) at #{MessageHelper.notification_time(notification)}"
      options[:html_body]  = "#{notification.notifier.full_name} notified you about <a href=\"#{MessageHelper.url_for(notification.item)}\">#{notification.item.name} (#{notification.item.class_humanize})</a> at #{MessageHelper.notification_time(notification)}"
      
      recipients(notification).each do |jabber_address|
        options[:to] = jabber_address.im_address
        send_message(options)
      end
    end
    
    def self.alarm(event)
      options              = {}
      options[:subject]    = "Connector Alarm"
      options[:plain_body] = "Event Alarm: #{event.name} at #{event.start_time.strftime('%D %T')} (#{event.location})"
      options[:html_body]  = "Event Alarm: <a href=\"#{MessageHelper.url_for(notification.item)}\">#{event.name}</a> at #{event.start_time.strftime('%D %T')} (#{event.location})"
      
      recipients(notification).each do |jabber_address|
        options[:to] = jabber_address.im_address
        send_message(options)
      end
    end
    
    def self.client
      return @@client if @@client && @@client.is_connected?
      
      @@client.close rescue
      
      jid      = Jabber::JID.new("#{@@sender_account}/connector")
      @@client = Jabber::Client.new(jid)
      @@client.connect
      @@client.auth(@@sender_password)

      @@client.add_message_callback do |message| 
        # log responses so we can see what people say back...maybe something useful could come out of this.
        @@received_file_log.info("#{Time.now.xmlschema} #{message.from.node}@#{message.from.domain}\t#{message.body}")

        case message.body
        when /time/i
          send_message(:to => message.from, :plain_body => Time.now.rfc2822)
        when /accept/i
          
        when /deny/i, /reject/i
          
          # keep a hash for the last message sent and a link to the id of the notification
        end
      end
      
      @@client
    end
    
    private
    
    # Client will fall back to plain_text if the html_text won't work.
    def self.send_message(options)
      @@counter += 1
      message    = Jabber::Message.new(options[:to], options[:plain_body]).set_type(:normal).set_id(@@counter.to_s).set_subject(options[:subject])
      
      if options[:html_body]
        html = REXML::Element::new("html")
        html.add_namespace('http://jabber.org/protocol/xhtml-im')

        body = REXML::Element::new("body")
        body.add_namespace('http://www.w3.org/1999/xhtml')

        text = REXML::Text.new(options[:html_body], false, body, true, nil, %r/.^/ )

        html.add(body)

        message.add_element(html)
        puts message.to_s
      end
      
      client.send(message)
    end
    
    def self.recipients(notification)
      notification.notifiee.person.im_addresses.select{|im| im.use_notifier? && im.im_type == 'Jabber'}
    end
  end
end