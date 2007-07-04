# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is governed
# by either the GPLv2 or Joyent Commercial Software licenses.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$

require 'config/environment'
require 'net/imap'
require 'ostruct'
require File.dirname(__FILE__) + '/../lib/net_imap_hax'

users = User.find(:all)
users.each do |user|
  # skip this 'whozma' nonsense
  next if user.username == 'whozma'
  
  puts '****************************************'
  puts user.username
  puts '****************************************'
  
  # imap connection, raw like
  imap = Net::IMAP.new(ENV['IMAP_HOST'] || 'connector.joyent.com')
  imap.login(ENV['IMAP_USER'] || user.system_email, ENV['IMAP_PASS'] || user.plaintext_password)
  
  user.mailboxes.each do |mb|
    imap.examine mb.full_name
    mb.messages.each do |message|
      puts "#{mb.full_name} : #{message.id}, #{message.uid}"
      imsg = imap.uid_fetch(message.uid, '(FLAGS ENVELOPE INTERNALDATE BODYSTRUCTURE)')
      next if imsg.nil?
      imsg = imsg.first
      
      flags           = OpenStruct.new
      flags.answered  = imsg.attr['FLAGS'].any?{ |flag| flag == :Answered }
      flags.flagged   = imsg.attr['FLAGS'].any?{ |flag| [:Flagged, '$Important'].include? flag }
      flags.draft     = imsg.attr['FLAGS'].any?{ |flag| flag == :Draft }
      flags.forwarded = imsg.attr['FLAGS'].any?{ |flag| flag == '$Forwarded' }
      flags.junk      = imsg.attr['FLAGS'].any?{ |flag| ['$AutoJunk', '$AutoMaybeJunk', '$Junk'].include?(flag) and ! ['$AutoNotJunk', '$NotJunk'].include?(flag) }
      
      message.update_attributes(
        :sender          => imsg.attr['ENVELOPE'].from || '',
        :subject         => imsg.attr['ENVELOPE'].subject,
        :date            => Time.parse(imsg.attr['ENVELOPE'].date || imsg.attr['INTERNALDATE']).utc,
        :has_attachments => imsg.attr['BODYSTRUCTURE'].multipart?,
        :flags           => flags,
        :seen            => imsg.attr['FLAGS'].any?{ |flag| flag == :Seen })
    end
  end
end