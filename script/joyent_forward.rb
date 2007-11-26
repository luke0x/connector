#!/usr/bin/env ruby
# ++
# Copyright 2004-2007 Joyent Inc.
# 
# Redistribution and/or modification of this code is 
# governed by the GPLv2.
# 
# Report issues and contribute at http://dev.joyent.com/
# 
# $Id$
# --


require File.dirname(__FILE__) + '/../config/boot'
# It complains about a file being required without RAILS_ROOT appended
begin
  require "#{RAILS_ROOT}/config/environment"
rescue MissingSourceFile
  if File.exists? "#{File.expand_path(RAILS_ROOT)}/override_config.rb"
    require "#{RAILS_ROOT}/override_config"
  end
end

# Take the SMTP mail settings

host     = ENV['SMTP_HOST'] || JoyentConfig.smtp_host
smtp_user= ENV['SMTP_USER'] || nil
pass     = ENV['SMTP_PASS'] || nil
auth     = ENV['SMTP_AUTH'] || nil
port     = ENV['SMTP_PORT'] || 25

require 'logger'
logfile = File.expand_path("#{RAILS_ROOT}/log/joyent_forward.log")
logger = Logger.new(logfile)
logger.info("#{Time.now.to_s}: Mail forwarding started...")


loop do
  logger.info("#{Time.now.to_s}: Processing organizations ...")
  orgs = Organization.find(:all, :include => :users, :conditions => ["users.forward_address <> ''"])

  orgs.each do |org|

    org.users.each do |user|
      # User preferred email addresses and all the email addresses
      preferred_email = user.person.email_addresses.find(:first, :conditions => ["preferred=?",true]).email_address
      email_addresses = user.person.email_addresses.collect {|addr| addr.email_address}

      ibx = user.mailboxes.find_by_full_name 'INBOX'
      ibx.sync
      # Get active messages not seen:
      not_seen = ibx.messages.find(:all, :conditions => ["(seen = ? OR seen IS NULL) AND messages.active = ?", false, true])
      
      not_seen.each do |m|
        if m.exist?
          @tmail = TMail::Mail.parse(m.raw)
          # This should be the addrress we've received the mail
          delivered = email_addresses.detect {|a| @tmail.to.to_a.include?(a) || @tmail.cc.to_a.include?(a) || @tmail.bcc.to_a.include?(a)} || preferred_email
          # Append forwarding headers
          @tmail['Delivered-To'] = @tmail.to.to_a.join(', ')
          @tmail['X-Forwarded-For'] = "#{delivered} #{user.forward_address}"
          @tmail['X-Forwarded-To'] = "#{user.forward_address}"
          # We're going to deliver the email to the addresses selected for forwarding
          @tmail['to'] = "#{user.forward_address}"

          # logger.info @tmail.to_s

          begin
            unless ENV['RAILS_ENV'] == 'test'
              Net::SMTP.start(host, port, host, smtp_user, pass, auth) do |smtp|
                smtp.send_message @tmail.encoded, @tmail.from, @tmail.destinations
              end
            end
          rescue Exception => e
            logger.error "smtp error: " + e.to_s.inspect + "(#{e.class})"
          end
          # Mark it as seen and read even if we have an error from SMTP
          m.seen!

        end
      end
      
    end
  end
  logger.info("#{Time.now.to_s}: ... organizations processed")
  # wait for a minute and start again, (trying to avoid memory growing without limits)
  sleep(60)
end

