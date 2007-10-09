=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

class MessageStatusCache < ActiveRecord::Migration
  def self.up
    add_column "messages", "status", :text
    
    Message.find(:all).each do |message|
      # blow away proxies that have no metadata
      if message.comments.blank? && message.tags.blank? && message.notifications.blank? && message.permissions.blank?
        message.destroy
        next
      end

      # Massage sender/recipient fields with new data structure
      # This will also update the message status cache field
      senders = message.sender.inject([]) do |arr, sender|
        if sender.name.blank?
          arr << JoyentMaildir::MailParser::MailAddress.new("#{sender.mailbox}@#{sender.host}")
        else
          arr << JoyentMaildir::MailParser::MailAddress.new("#{sender.name} <#{sender.mailbox}@#{sender.host}>")
        end
        arr
      end

      recipients = message.recipients.inject([]) do |arr, recipient|
        if recipient.name.blank?
          arr << JoyentMaildir::MailParser::MailAddress.new("#{recipient.mailbox}@#{recipient.host}")
        else
          arr << JoyentMaildir::MailParser::MailAddress.new("#{recipient.name} <#{recipient.mailbox}@#{recipient.host}>")
        end
        arr
      end

      # This will also update messages status
      message.update_attributes :sender => senders, :recipients => recipients
    end
  end

  def self.down
    remove_column "messages", "status"
  end
end