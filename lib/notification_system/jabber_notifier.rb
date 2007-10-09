=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)
# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is governed
# by either the GPLv2 or Joyent Commercial Software licenses.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$
require 'xmpp4r/client'

module NotificationSystem
  class JabberNotifier
    cattr_accessor :sender_account, :sender_password
    @@sender_account    = JoyentConfig.jabber_notifier_account
    @@sender_password   = JoyentConfig.jabber_notifier_password

    @@received_file_log = Logger.new("#{RAILS_ROOT}/log/received_jabbers.log")
    @@client            = nil
    @@counter           = Time.now.to_i
    
    def self.notify(notification)
      options              = {}
      options[:subject]    = "Connector Notification"
      options[:plain_body] = "#{notification.notifier.full_name} notified you about #{notification.item.name} (#{notification.item.class_humanize}) at #{MessageHelper.notification_time(notification)}"
      options[:html_body]  = "#{notification.notifier.full_name} notified you about <a href=\"#{MessageHelper.url_for(notification.item)}\">#{notification.item.name} (#{notification.item.class_humanize})</a> at #{MessageHelper.notification_time(notification)}"
      
      jabber_recipients(notification.notifiee).each do |jabber_address|
        options[:to] = jabber_address.im_address
        send_message(options)
      end
    end
                                                                    
    # FIXME: Looks like the time in these does not respect the recurrence
    def self.alarm(event, user)
      options              = {}
      options[:subject]    = "Connector Alarm"
      options[:plain_body] = "Event Alarm: #{event.name} at #{event.alarm_time_in_user_tz.strftime('%D %I:%M %p')} (#{event.location})"
      options[:html_body]  = "Event Alarm: <a href=\"#{MessageHelper.url_for(event)}\">#{event.name}</a> at #{event.alarm_time_in_user_tz.strftime('%D %I:%M %p')} (#{event.location})"
      
      jabber_recipients(user).each do |jabber_address|
        options[:to] = jabber_address.im_address
        send_message(options)
      end
    end
    
    private

    def self.client
      return @@client if @@client && @@client.is_connected?
      
      @@client.close rescue
      
      jid      = Jabber::JID.new("#{@@sender_account}/connector_#{(rand*10000).round}")
      @@client = Jabber::Client.new(jid)
      @@client.connect
      @@client.auth(@@sender_password)

      @@client.add_message_callback do |message| 
        # log responses so we can see what people say back...maybe something useful could come out of this.
        @@received_file_log.info("#{Time.now.xmlschema} #{message.from.node}@#{message.from.domain}\t#{message.body}")

        # Proof of concept
        case message.body
        when /\btime\b/i
          send_message(:to => message.from, :plain_body => Time.now.rfc2822, :subject => "Time")
        # when /\bdismiss\b/i, /\back\b/i, /\backnowledge\b/i
        # when /accept/i
        # when /deny/i, /reject/i
        #   # keep a hash for the last message sent and a link to the id of the notification, or
        #   # require the id of the object to come in too
        end
      end
      
      @@client
    end
        
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
      end
      
      client.send(message)
    end
    
    def self.jabber_recipients(user)
      user.person.im_addresses.select{|im| im.use_notifier? && (im.im_type == 'Jabber' || im.im_type == 'Google Talk')}
    end
  end
end