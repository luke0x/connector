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
      plain_msg = "#{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize}) at #{MessageHelper.notification_time(notification)}"
      html_msg  = "#{notification.notifier.full_name} notified you about <a href=\"#{MessageHelper.url_for(notification.item)}\">#{notification.item.name} (#{notification.item.class_humanize})</a> at #{MessageHelper.notification_time(notification)}"
      tos       = notification.notifiee.person.im_addresses.select{|im| im.notify? && im.type == 'Jabber'}
      
      tos.each do |jabber_address|
        send_message(jabber_address.im_address, plain_msg, html_msg)
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
          send_message(message.from, Time.now.rfc2822)
        when /accept/i
          
        when /deny/i, /reject/i
          
          # keep a hash for the last message sent and a link to the id of the notification
        end
      end
      
      @@client
    end
    
    # Client will fall back to plain_text if the html_text won't work.
    def self.send_message(recipient, plain_text, html_text=nil)
      @@counter += 1
      message    = Jabber::Message.new(recipient, plain_text).set_type(:normal).set_id(@@counter.to_s).set_subject('Connector Notification')
      
      if html_text
        html = REXML::Element::new("html")
        html.add_namespace('http://jabber.org/protocol/xhtml-im')

        body = REXML::Element::new("body")
        body.add_namespace('http://www.w3.org/1999/xhtml')

        text = REXML::Text.new(html_text, false, body, true, nil, %r/.^/ )

        html.add(body)

        message.add_element(html)
        puts message.to_s
      end
      
      client.send(message)
    end
  end
end