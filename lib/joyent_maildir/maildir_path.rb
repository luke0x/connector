=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

module JoyentMaildir
  class MaildirPath
    def self.build(domain, username, mailbox)
      mail_root  = ENV['JOYENT_MAILDIR'] || '/home/vmail'
      
      return File.join(mail_root, domain, username, 'Maildir') if mailbox.upcase == 'INBOX'
      
      path_parts = mailbox.sub(/^INBOX\./, '.')#.split('.').map {|p| ".#{p}"}      
      
      File.join(mail_root, domain, username, 'Maildir', *path_parts)
    end
    
    def self.generate_file_name
      mid          = "CON#{rand(100000)}#{Time.now.to_i.to_s}#{Process.pid}"
      filebase     = "#{Time.now.to_i.to_s}.#{mid}.connector"
      "#{filebase}:2,"
    end
  end
end