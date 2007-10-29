=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'ostruct'
require 'fileutils'
require File.dirname(__FILE__) + '/mail_parser'
require 'drb'

module JoyentMaildir
  class Message
    def initialize(message)
      @message  = message
      @username = message.owner.username
      @domain   = message.owner.organization.system_domain.email_domain
      
      @path = MaildirPath.build(@domain, @username, message.mailbox.full_name)
      @file = get_filename
    end
    
    def exist?
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.file.exist?(File.join(@path, 'cur', @file))
      end
    end
    
    # Can only do one of the filename based supported flags, for now.
    def flag
      unless flags.include?('F')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file_utils.mv(File.join(@path, 'cur', @file), File.join(@path, 'cur', add_flag('F')))
        end
      end
    end
        
    def unflag
      if flags.include?('F')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file_utils.mv(File.join(@path, 'cur', @file), File.join(@path, 'cur', remove_flag('F')))
        end
      end
    end
    
    def seen      
      unless flags.include?('S')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file_utils.mv(File.join(@path, 'cur', @file), File.join(@path, 'cur', add_flag('S')))
        end
      end
    end
    
    def draft
      unless flags.include?('D')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file_utils.mv(File.join(@path, 'cur', @file), File.join(@path, 'cur', add_flag('D')))
        end
      end
    end
    
    def answered
      unless flags.include?('R')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file_utils.mv(File.join(@path, 'cur', @file), File.join(@path, 'cur', add_flag('R')))
        end
      end
    end
    
    def forwarded
      unless flags.include?('P')
        RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
          MockFS.file_utils.mv(File.join(@path, 'cur', @file), File.join(@path, 'cur', add_flag('P')))
        end
      end
    end
    
    def delete
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.file.delete(File.join(@path, 'cur', @file))
      end
    end
    
    def copy_to(mailbox)
      new_base = MaildirPath.generate_file_name
      new_base += flags.join
      dest_path = File.join(MaildirPath.build(@domain, mailbox.owner.username, mailbox.full_name), 'cur', new_base)
      
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        src_path = File.join(@path, 'cur', @file)
        src_time = MockFS.file.mtime(src_path)
        MockFS.file_utils.cp(src_path, dest_path)
        MockFS.file.utime(src_time, src_time, dest_path)
      end
      new_base
    end
    
    def move_to(mailbox)
      new_base  = MaildirPath.generate_file_name
      new_base  += flags.join
      dest_path = File.join(MaildirPath.build(@domain, @username, mailbox.full_name), 'cur', new_base)
      
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.file_utils.mv(File.join(@path, 'cur', @file), dest_path)
      end
      new_base
    end
    
    def fetch
      OpenStruct.new self.parsed
    end
    
    def raw
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        MockFS.file.open(File.join(@path, 'cur', @file), 'r').read
      end
    end
    
    def parsed
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        JoyentMaildir::MailParser.parse_message(MockFS.file.open(File.join(@path, 'cur', @file)))
      end
    end
    
    def body(text_only=false)
      file = File.join(@path, 'cur', @file)
      flags = text_only ? '-t' : ''
      
      f = IO.popen("#{RAILS_ROOT}/vendor/mime_filter/gmime/gmime #{flags} \"#{file}\"", 'r')
      data = f.read
      f.close
      unless $?.success?
        raise JoyentMaildir::MessageParseException.new(data, file)
      end
                                
      # In the case that there is not a plain text version, we will just strip
      # the tags out of the html version and call it good
      if text_only && data.strip.blank?
        body(false).gsub(/<\/?[^>]*>/, "")
      else
        data
      end
    end
    
    def flags
      @file =~ /.+:2,(D?F?P?R?S?T?)/
      $1.split('')
    end

    private

    def get_filename
      file = ''
      RunAs.run_as(JoyentConfig.maildir_owner, JoyentConfig.maildir_group) do
        file = MockFS.dir.entries(File.join(@path, 'cur')).find {|f| f =~ /^#{@message.filename}:/}
      end
      raise MaildirFileNotFound.new(@message, @path) if file.nil?
      file
    end
    
    def add_flag(flag)
      f = flags
      f << flag
      "#{base}:2,#{f.uniq.sort.join}"      
    end
    
    def remove_flag(flag)
      f = flags
      f.delete 'F'
      "#{base}:2,#{f.uniq.sort.join}"
    end
    
    def base
      @file =~ /(.+):2,D?F?P?R?S?T?/
      $1
    end
    
  end
end
